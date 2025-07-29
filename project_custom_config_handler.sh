#!/bin/bash
echo "This script checks for custom codespell and pre-commit configurations."

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# Check for ../formatting_config/pre-commit-config.yaml
if [ -f "$SCRIPT_DIR/../formatting_config/pre-commit-config.yaml" ]; then
    echo "Custom pre-commit configuration found."
    cp "$SCRIPT_DIR/../formatting_config/pre-commit-config.yaml" "$SCRIPT_DIR/.pre-commit-config.yaml"
else
    echo "No custom pre-commit configuration found."
fi

# Check for ../formatting_config/exclude-file.txt
if [ -f "$SCRIPT_DIR/../formatting_config/exclude-file.txt" ]; then
    echo "Custom codespell exclude file found."
    cp "$SCRIPT_DIR/../formatting_config/exclude-file.txt" "$SCRIPT_DIR/tools/.codespell/exclude-file.txt"
else
    echo "No custom codespell exclude file found."
fi

# Check for ../formatting_config/ignore-words.txt
if [ -f "$SCRIPT_DIR/../formatting_config/ignore-words.txt" ]; then
    echo "Custom codespell ignore words file found."
    cp "$SCRIPT_DIR/../formatting_config/ignore-words.txt" "$SCRIPT_DIR/tools/.codespell/ignore-words.txt"
else
    echo "No custom codespell ignore words file found."
fi

echo "Custom configuration check completed."
