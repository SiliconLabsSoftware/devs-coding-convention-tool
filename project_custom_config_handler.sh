#!/bin/bash

WORKSPACE_DIR="/src"
ACTION_DIR="/action"

CUSTOM_IGNORE_WORDS=${CUSTOM_IGNORE_WORDS:-""}
CUSTOM_EXCLUDE_FILE=${CUSTOM_EXCLUDE_FILE:-""}
CUSTOM_PRE_COMMIT_CONFIG=${CUSTOM_PRE_COMMIT_CONFIG:-""}

if [ -n "$CUSTOM_PRE_COMMIT_CONFIG" ] && [ -f "$WORKSPACE_DIR/$CUSTOM_PRE_COMMIT_CONFIG" ]; then
    echo "Custom pre-commit configuration found at: $CUSTOM_PRE_COMMIT_CONFIG"
    cp "$WORKSPACE_DIR/$CUSTOM_PRE_COMMIT_CONFIG" "$ACTION_DIR/.pre-commit-config.yaml"
fi

if [ -n "$CUSTOM_EXCLUDE_FILE" ] && [ -f "$WORKSPACE_DIR/$CUSTOM_EXCLUDE_FILE" ]; then
    echo "Custom codespell exclude file found at: $CUSTOM_EXCLUDE_FILE"
    cp "$WORKSPACE_DIR/$CUSTOM_EXCLUDE_FILE" "$ACTION_DIR/tools/.codespell/exclude-file.txt"
fi

if [ -n "$CUSTOM_IGNORE_WORDS" ] && [ -f "$WORKSPACE_DIR/$CUSTOM_IGNORE_WORDS" ]; then
    echo "Custom codespell ignore words file found at: $CUSTOM_IGNORE_WORDS"
    cp "$WORKSPACE_DIR/$CUSTOM_IGNORE_WORDS" "$ACTION_DIR/tools/.codespell/ignore-words.txt"
fi
