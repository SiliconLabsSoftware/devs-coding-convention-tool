#!/bin/bash
set -e

WORKSPACE_DIR="/src"
cd "$WORKSPACE_DIR" || exit 1

git config --global --add safe.directory "$WORKSPACE_DIR"

echo "=== Configuration Status ==="
echo "CUSTOM_EXCLUDE_FILE: ${CUSTOM_EXCLUDE_FILE:-<not set>}"
echo "CUSTOM_IGNORE_WORDS: ${CUSTOM_IGNORE_WORDS:-<not set>}"
echo "CUSTOM_PRE_COMMIT_CONFIG: ${CUSTOM_PRE_COMMIT_CONFIG:-<not set>}"
echo "==========================="

CUSTOM_SCRIPT="${1:-project_custom_config_handler.sh}"

if [ -n "$CUSTOM_SCRIPT" ] && [ -f "$CUSTOM_SCRIPT" ]; then
    echo "Running custom config script: $CUSTOM_SCRIPT"
    chmod +x "$CUSTOM_SCRIPT"
    ./"$CUSTOM_SCRIPT"
elif [ -n "$CUSTOM_SCRIPT" ] && [ "$CUSTOM_SCRIPT" != "project_custom_config_handler.sh" ]; then
    echo "Error: Custom script specified but not found: $CUSTOM_SCRIPT"
    exit 1
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
