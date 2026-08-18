#!/usr/bin/env python3
"""Find org repos that use devs-coding-convention-tool and have a passing last run."""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import re
import subprocess
import sys
import time

WORKFLOW_PATH = ".github/workflows/00-Check-Code-Convention.yml"
WORKFLOW_FILE = "00-Check-Code-Convention.yml"
USES_PATTERN = re.compile(r"uses:\s*SiliconLabsSoftware/devs-coding-convention-tool")
ACTION_REF_PATTERN = re.compile(
    r"uses:\s*SiliconLabsSoftware/devs-coding-convention-tool@([^\s#]+)"
)
INPUT_NAMES = ("exclude-regex", "codespell-ignore-words", "codespell-skip-paths")


def run_gh(args: list[str], check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["gh", *args],
        capture_output=True,
        text=True,
        check=check,
    )


def ensure_gh_ready() -> None:
    if run_gh(["auth", "status"]).returncode != 0:
        print("error: gh is not authenticated (run: gh auth login)", file=sys.stderr)
        sys.exit(1)


def list_org_repos(org: str) -> list[str]:
    result = run_gh(
        ["api", f"orgs/{org}/repos", "--paginate", "--jq", ".[].name"],
        check=True,
    )
    return [line for line in result.stdout.splitlines() if line]


def fetch_last_run(org: str, repo_name: str) -> tuple[dict | None, str | None]:
    full_name = f"{org}/{repo_name}"
    result = run_gh(
        [
            "api",
            (
                f"repos/{full_name}/actions/workflows/{WORKFLOW_FILE}/runs"
                "?per_page=1"
            ),
            "--jq",
            (
                ".workflow_runs[0] | "
                "if . == null then null else "
                "{status, conclusion, url: .html_url, created_at, head_branch, "
                "event, run_number} end"
            ),
        ]
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "api error"
        return None, detail

    raw = result.stdout.strip()
    if not raw or raw == "null":
        return None, None
    return json.loads(raw), None


def last_run_successful(last_run: dict | None) -> bool:
    return (
        last_run is not None
        and last_run.get("status") == "completed"
        and last_run.get("conclusion") == "success"
    )


def fetch_workflow(org: str, repo_name: str) -> str | None:
    full_name = f"{org}/{repo_name}"
    result = run_gh(
        [
            "api",
            f"repos/{full_name}/contents/{WORKFLOW_PATH}",
            "-H",
            "Accept: application/vnd.github.raw",
        ]
    )
    if result.returncode != 0 or not result.stdout:
        return None
    return result.stdout


def parse_scalar(raw: str) -> str:
    value = raw.strip()
    if not value or value in ("''", '""'):
        return ""
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def join_multiline_scalar(parts: list[str]) -> str:
    if not parts:
        return ""

    combined = parts[0].rstrip()
    for part in parts[1:]:
        piece = part.strip()
        if combined.endswith("\\"):
            combined = combined[:-1] + piece
        else:
            combined += piece
    return combined


def scalar_complete(raw: str) -> bool:
    value = raw.strip()
    if not value or value in ("''", '""'):
        return True
    if value[0] not in ("'", '"'):
        return True

    quote = value[0]
    i = 1
    while i < len(value):
        ch = value[i]
        if ch == "\\":
            i += 2
            continue
        if ch == quote:
            return value[i + 1:].strip() == ""
        i += 1
    return False


def extract_input_value(content: str, field_name: str) -> str:
    match = re.search(
        rf"^[ \t]+{re.escape(field_name)}:\s*(.*)$",
        content,
        re.MULTILINE,
    )
    if not match:
        return ""

    key_line_start = content.rfind("\n", 0, match.start()) + 1
    key_line_end = content.find("\n", match.start())
    key_line = content[key_line_start:(key_line_end if key_line_end != -1 else len(content))]
    key_indent = len(key_line) - len(key_line.lstrip(" \t"))

    parts = [match.group(1)]
    combined = join_multiline_scalar(parts)
    if scalar_complete(combined):
        return parse_scalar(combined)

    pos = match.end()
    if pos < len(content) and content[pos] == "\n":
        pos += 1

    while pos < len(content):
        line_end = content.find("\n", pos)
        line = content[pos:(line_end if line_end != -1 else len(content))]

        if not line.strip():
            if scalar_complete(join_multiline_scalar(parts)):
                break
            if line_end == -1:
                break
            pos = line_end + 1
            continue

        indent = len(line) - len(line.lstrip(" \t"))
        if indent <= key_indent:
            break

        parts.append(line.strip())
        if scalar_complete(join_multiline_scalar(parts)):
            break

        if line_end == -1:
            break
        pos = line_end + 1

    return parse_scalar(join_multiline_scalar(parts))


def parse_workflow(content: str) -> dict[str, str] | None:
    if "devs-coding-convention-tool" not in content:
        return None

    uses_match = ACTION_REF_PATTERN.search(content)
    action_ref = uses_match.group(1) if uses_match else ""

    fields: dict[str, str] = {}
    for name in INPUT_NAMES:
        key = name.replace("-", "_")
        fields[key] = extract_input_value(content, name)

    return {
        "action_ref": action_ref,
        "exclude_regex": fields["exclude_regex"],
        "codespell_ignore_words": fields["codespell_ignore_words"],
        "codespell_skip_paths": fields["codespell_skip_paths"],
    }


def check_repo(org: str, repo_name: str) -> dict | None:
    content = fetch_workflow(org, repo_name)
    if content is None or not USES_PATTERN.search(content):
        return None

    inputs = parse_workflow(content)
    if inputs is None:
        full_name = f"{org}/{repo_name}"
        print(f"warning: could not parse inputs for {full_name}", file=sys.stderr)
        return None

    full_name = f"{org}/{repo_name}"

    last_run, api_error = fetch_last_run(org, repo_name)
    if api_error is not None:
        print(f"skip {full_name}: could not read workflow runs ({api_error})", file=sys.stderr)
        return None
    if not last_run_successful(last_run):
        if last_run is None:
            reason = "no runs found"
        else:
            reason = f"{last_run.get('status')}/{last_run.get('conclusion')}"
        print(f"skip {full_name}: last run not successful ({reason})", file=sys.stderr)
        return None

    print(full_name)
    return {
        "full_name": full_name,
        "repo": repo_name,
        **inputs,
        "last_run": last_run,
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Find repos using devs-coding-convention-tool whose last workflow run succeeded."
        )
    )
    parser.add_argument(
        "output",
        nargs="?",
        default="repos.json",
        help="Output JSON path (default: repos.json)",
    )
    args = parser.parse_args()

    org = os.environ.get("ORG", "SiliconLabsSoftware")
    parallel = int(os.environ.get("PARALLEL", "8"))

    ensure_gh_ready()

    started = time.monotonic()
    print(f"Listing repositories in {org}...")
    repo_names = list_org_repos(org)
    print(
        f"Checking {len(repo_names)} repositories at {WORKFLOW_PATH} "
        f"(parallel={parallel})..."
    )

    repos: list[dict] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
        futures = [
            executor.submit(check_repo, org, repo_name) for repo_name in repo_names
        ]
        for future in concurrent.futures.as_completed(futures):
            record = future.result()
            if record is not None:
                repos.append(record)

    repos.sort(key=lambda item: item["full_name"])

    with open(args.output, "w", encoding="utf-8") as fp:
        json.dump({"repos": repos}, fp, indent=2)
        fp.write("\n")

    elapsed = int(time.monotonic() - started)
    if not repos:
        print(f"Found 0 repos with a successful last run ({elapsed}s)")
        return

    print(
        f"Found {len(repos)} repos with a successful last run "
        f"({elapsed}s, written to {args.output})"
    )


if __name__ == "__main__":
    main()
