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

if [ -n "$EXCLUDE_REGEX" ] || [ -n "$CODESPELL_IGNORE_WORDS" ] || [ -n "$CODESPELL_SKIP_PATHS" ]; then
    SCRIPT_PATH="$ACTION_REPO_DIR/handle_custom_inputs.py"
    if [ ! -s "$SCRIPT_PATH" ]; then
        echo "ERROR: missing or empty handler script: $SCRIPT_PATH" >&2
        exit 1
    fi
    python3 "$SCRIPT_PATH"
fi

echo "Installing pre-commit hooks..."
pre-commit install-hooks --config /action/.pre-commit-config.yaml

echo "Running pre-commit..."
set +e
pre-commit run --config /action/.pre-commit-config.yaml --all-files 2>&1 | tee CodingConventionTool.txt
PC_EXIT=${PIPESTATUS[0]}
set -e

git diff > code-fix.patch || echo "No changes to patch."

#remove pre-commit .cache folder to not pollute the sw repo git status
rm -rf .cache 

if [ "$PC_EXIT" -ne 0 ]; then
    echo "Pre-commit failed with exit code $PC_EXIT"
    exit "$PC_EXIT"
fi
