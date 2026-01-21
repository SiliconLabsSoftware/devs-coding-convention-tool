#!/bin/bash
set -e

SW_REPO_DIR="/src"
ACTION_REPO_DIR="/action"

# Set cache directories for pre-commit (non-root user needs writable location)
export HOME="$SW_REPO_DIR"
export XDG_CACHE_HOME="$SW_REPO_DIR/.cache"

cd "$SW_REPO_DIR" || exit 1

git config --system --add safe.directory "$SW_REPO_DIR" 2>/dev/null || \
git config --add safe.directory "$SW_REPO_DIR"

echo "=== Configuration Status ==="
echo "CUSTOM_EXCLUDE_FILE: ${CUSTOM_EXCLUDE_FILE:-<not set>}"
echo "CUSTOM_IGNORE_WORDS: ${CUSTOM_IGNORE_WORDS:-<not set>}"
echo "CUSTOM_PRE_COMMIT_CONFIG: ${CUSTOM_PRE_COMMIT_CONFIG:-<not set>}"
echo "==========================="

# Handle custom configuration

if [ -n "$CUSTOM_PRE_COMMIT_CONFIG" ]; then
    if [ -f "$SW_REPO_DIR/$CUSTOM_PRE_COMMIT_CONFIG" ]; then
        echo "Applying custom pre-commit config: $CUSTOM_PRE_COMMIT_CONFIG"
        cp "$SW_REPO_DIR/$CUSTOM_PRE_COMMIT_CONFIG" "$ACTION_REPO_DIR/.pre-commit-config.yaml"
    else
        echo "Warning: Custom pre-commit config not found: $CUSTOM_PRE_COMMIT_CONFIG"
    fi
fi

if [ -n "$CUSTOM_EXCLUDE_FILE" ]; then
    if [ -f "$SW_REPO_DIR/$CUSTOM_EXCLUDE_FILE" ]; then
        echo "Applying custom exclude file: $CUSTOM_EXCLUDE_FILE"
        cp "$SW_REPO_DIR/$CUSTOM_EXCLUDE_FILE" "$ACTION_REPO_DIR/tools/.codespell/exclude-file.txt"
    else
        echo "Warning: Custom exclude file not found: $CUSTOM_EXCLUDE_FILE"
    fi
fi

if [ -n "$CUSTOM_IGNORE_WORDS" ]; then
    if [ -f "$SW_REPO_DIR/$CUSTOM_IGNORE_WORDS" ]; then
        echo "Applying custom ignore words: $CUSTOM_IGNORE_WORDS"
        cp "$SW_REPO_DIR/$CUSTOM_IGNORE_WORDS" "$ACTION_REPO_DIR/tools/.codespell/ignore-words.txt"
    else
        echo "Warning: Custom ignore words file not found: $CUSTOM_IGNORE_WORDS"
    fi
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
