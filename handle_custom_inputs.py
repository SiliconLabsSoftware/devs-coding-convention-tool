#!/usr/bin/env python3
from __future__ import annotations

"""
Apply optional container inputs to pre-commit and codespell configs.
"""

import os
import sys
from pathlib import Path

ACTION_REPO_DIR = Path(os.environ.get("ACTION_REPO_DIR", "/action"))
PRE_COMMIT_CONFIG_PATH = ACTION_REPO_DIR / ".pre-commit-config.yaml"
CODESPELL_IGNORE_WORDS_PATH = ACTION_REPO_DIR / "tools/.codespell/ignore-words.txt"
CODESPELL_CONFIG_PATH = ACTION_REPO_DIR / "tools/.codespell/.codespellrc"


def _append_exclude_regex(config_path: Path, exclude_regex: str) -> None:
    if not config_path.exists():
        print(f"ERROR: pre-commit config missing: {config_path}", file=sys.stderr)
        sys.exit(1)
    if config_path.stat().st_size == 0:
        print(f"ERROR: pre-commit config is empty: {config_path}", file=sys.stderr)
        sys.exit(1)
    lines = config_path.read_text().splitlines()
    out = []
    updated = False
    for line in lines:
        if not updated and line.startswith("exclude: "):
            existing = line[len("exclude: ") :].strip().strip("'\"")
            combined = f"{existing}|{exclude_regex}" if existing else exclude_regex
            out.append(f"exclude: '{combined}'")
            updated = True
        else:
            out.append(line)
    if not updated:
        print("ERROR: no exclude line found in pre-commit config", file=sys.stderr)
        sys.exit(1)
    config_path.write_text("\n".join(out) + "\n")


def _append_codespell_ignore_words(ignore_words_path: Path, ignore_words: str) -> None:
    if not ignore_words_path.exists():
        print(f"ERROR: codespell ignore words file missing: {ignore_words_path}", file=sys.stderr)
        sys.exit(1)
    words = [w.strip() for w in ignore_words.split(",") if w.strip()]
    if not words:
        return
    with ignore_words_path.open("a", encoding="utf-8") as handle:
        for word in words:
            handle.write(word + "\n")


def _append_codespell_skip_paths(config_path: Path, skip_paths: str) -> None:
    if not config_path.exists():
        print(f"ERROR: codespell config missing: {config_path}", file=sys.stderr)
        sys.exit(1)
    if config_path.stat().st_size == 0:
        print(f"ERROR: codespell config is empty: {config_path}", file=sys.stderr)
        sys.exit(1)
    additions = [p.strip() for p in skip_paths.split(",") if p.strip()]
    if not additions:
        return
    lines = config_path.read_text().splitlines()
    out = []
    updated = False
    for line in lines:
        if line.startswith("skip = "):
            current = line[len("skip = ") :].strip()
            combined = ",".join([p for p in [current, *additions] if p])
            out.append(f"skip = {combined}")
            updated = True
        else:
            out.append(line)
    if not updated:
        print("ERROR: no skip line found in codespell config", file=sys.stderr)
        sys.exit(1)
    config_path.write_text("\n".join(out) + "\n")


def main() -> int:
    if not ACTION_REPO_DIR.exists() or not ACTION_REPO_DIR.is_dir():
        print(f"ERROR: action repo dir missing or not a directory: {ACTION_REPO_DIR}", file=sys.stderr)
        return 1

    exclude_regex = os.environ.get("EXCLUDE_REGEX", "")
    codespell_ignore_words = os.environ.get("CODESPELL_IGNORE_WORDS", "")
    codespell_skip_paths = os.environ.get("CODESPELL_SKIP_PATHS", "")

    if not any([exclude_regex, codespell_ignore_words, codespell_skip_paths]):
        return 0

    if exclude_regex:
        print("Appending to pre-commit exclude regex pattern.")
        print(f"Additional exclude regex (raw): {exclude_regex}")
        print("Additional exclude regex entries:")
        for entry in exclude_regex.split("|"):
            if entry:
                print(f" - {entry}")
        _append_exclude_regex(PRE_COMMIT_CONFIG_PATH, exclude_regex)

    if codespell_ignore_words:
        print(f"Adding codespell ignore words: {codespell_ignore_words}")
        _append_codespell_ignore_words(
            CODESPELL_IGNORE_WORDS_PATH, codespell_ignore_words
        )

    if codespell_skip_paths:
        print(f"Adding codespell skip paths: {codespell_skip_paths}")
        _append_codespell_skip_paths(
            CODESPELL_CONFIG_PATH, codespell_skip_paths
        )
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
