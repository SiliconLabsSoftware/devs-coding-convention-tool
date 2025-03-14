#!/bin/bash
echo "----------------------------------------------------------"
echo "Deactivating Developer Services Project Virtual Environment"
echo "----------------------------------------------------------"

# Check for the -h parameter
if [ "$1" == "-h" ]; then
    echo "Usage: deactivate_macos.sh [-c]"
    echo
    echo "Options:"
    echo "  -c    Clean virtual environment and remove installed programs"
    exit 0
fi

# Check for the -c parameter
if [ "$1" == "-c" ]; then
    echo "Cleaning virtual environment and removing installed programs..."

    # Deactivate the virtual environment
    if [ -f "venv/bin/deactivate" ]; then
        source venv/bin/deactivate
        echo "Virtual environment deactivated."
    else
        echo "Virtual environment is not active."
    fi

    # Remove the virtual environment directory
    if [ -d "venv" ]; then
        rm -rf venv
        echo "Virtual environment directory removed."
    else
        echo "Virtual environment directory does not exist."
    fi

    # Remove Uncrustify directory
    if [ -d "uncrustify" ]; then
        rm -rf uncrustify
        echo "Uncrustify directory removed."
    else
        echo "Uncrustify directory does not exist."
    fi

    # Remove other installed programs if necessary
    # Example: Remove Clang-tidy
    pip uninstall -y clang-tidy
    # Example: Remove cppcheck
    pip uninstall -y cppcheck

    echo "Cleaning completed."
    exit 0
fi

# Deactivate the virtual environment
if [ -f "venv/bin/deactivate" ]; then
    source venv/bin/deactivate
    echo "Virtual environment deactivated."
else
    echo "Virtual environment is not active."
fi

# Add any additional project-specific processes to stop here
# Example: Stop a specific service
# sudo launchctl stop "ServiceName"

echo "Project-specific processes stopped."
