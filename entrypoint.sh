#!/bin/bash
set -e

SW_REPO_DIR="/src"
ACTION_REPO_DIR="/action"

export XDG_CACHE_HOME="$SW_REPO_DIR/.cache"

cd "$SW_REPO_DIR" || exit 1

git config --global --add safe.directory "$SW_REPO_DIR"

echo "=== Configuration Status ==="
echo "EXCLUDE_REGEX: ${EXCLUDE_REGEX:-<not set>}"
echo "CODESPELL_IGNORE_WORDS: ${CODESPELL_IGNORE_WORDS:-<not set>}"
echo "CODESPELL_SKIP_PATHS: ${CODESPELL_SKIP_PATHS:-<not set>}"
echo "==========================="

# Inject exclude-regex into pre-commit config
if [ -n "$EXCLUDE_REGEX" ]; then
    echo "Appending exclude pattern: $EXCLUDE_REGEX"
    sed -i "s|^exclude: '\\(.*\\)'|exclude: '\\1|${EXCLUDE_REGEX}'|" "$ACTION_REPO_DIR/.pre-commit-config.yaml"
fi

# Inject ignore-words into codespell ignore list
if [ -n "$CODESPELL_IGNORE_WORDS" ]; then
    echo "Adding codespell ignore words: $CODESPELL_IGNORE_WORDS"
    echo "$CODESPELL_IGNORE_WORDS" | tr ',' '\n' >> "$ACTION_REPO_DIR/tools/.codespell/ignore-words.txt"
fi

# Inject skip-paths into codespell config
if [ -n "$CODESPELL_SKIP_PATHS" ]; then
    echo "Adding codespell skip paths: $CODESPELL_SKIP_PATHS"
    sed -i "s|^skip = \\(.*\\)|skip = \\1,${CODESPELL_SKIP_PATHS}|" "$ACTION_REPO_DIR/tools/.codespell/.codespellrc"
fi

echo "Installing pre-commit hooks..."
pre-commit install-hooks --config /action/.pre-commit-config.yaml

echo "Running pre-commit..."
set +e
pre-commit run --config /action/.pre-commit-config.yaml --all-files 2>&1 | tee CodingConventionTool.txt
PC_EXIT=${PIPESTATUS[0]}
set -e

git diff > code-fix.patch || echo "No changes to patch."

if [ "$PC_EXIT" -ne 0 ]; then
    echo "Pre-commit failed with exit code $PC_EXIT"
    exit "$PC_EXIT"
fi
