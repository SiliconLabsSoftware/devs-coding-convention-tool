#!/bin/bash
echo "----------------------------------------------------------"
echo "Activating Developer Services Project Virtual Environment"
echo "----------------------------------------------------------"

# Check if the script was called from a subfolder
if [[ "$(dirname "$0")" != "." ]]; then
    cd ..
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python not found. Please install Python 3.8 or later."
    exit 1
else
    echo "Python is installed."
fi

# Check if the virtual environment directory exists
if [ ! -d "venv" ]; then
    echo "Virtual environment not found. Creating one..."
    python3 -m venv venv
fi

# Activate the virtual environment
echo "Activating the virtual environment..."
source venv/bin/activate
echo "Virtual environment activated."

# Check if pre-commit is already installed
if ! pip show pre-commit &> /dev/null; then
    echo "pre-commit not found. Installing pre-commit..."
    pip install pre-commit
else
    echo "pre-commit is already installed."
fi

# Initialize pre-commit
echo "Initializing pre-commit..."
pre-commit install

# Check if CMake is already installed
if ! command -v cmake &> /dev/null; then
    echo "CMake not found. Installing latest CMake..."
    pip install cmake
else
    echo "CMake is already installed."
fi

# Check if Ninja is already installed
if ! command -v ninja &> /dev/null; then
    echo "Ninja not found. Installing latest Ninja..."
    pip install ninja
else
    echo "Ninja is already installed."
fi

# Clone and compile Uncrustify 0.64
if [ ! -d "uncrustify" ]; then
    echo "Uncrustify not found. Cloning Uncrustify..."
    git clone -b uncrustify-0.64 --single-branch https://github.com/uncrustify/uncrustify.git
    if [ $? -ne 0 ]; then
        echo "Failed to clone Uncrustify repository. Exiting..."
        exit 1
    fi
    echo "Compiling Uncrustify..."
    cd uncrustify
    mkdir build
    cd build
    cmake --build .
    if [ $? -ne 0 ]; then
        echo "Failed to compile Uncrustify. Exiting..."
        exit 1
    fi
    cd ../..
    echo "Uncrustify cloned and compiled."
    echo "Copying Uncrustify configuration file..."
    cp uncrustify.cfg uncrustify/uncrustify.cfg
else
    echo "Uncrustify is already cloned and compiled."
fi

# Install Clang-tidy
if ! command -v clang-tidy &> /dev/null; then
    echo "Clang-tidy not found. Installing Clang-tidy..."
    pip install clang-tidy
else
    echo "Clang-tidy is already installed."
fi

# Install cppcheck
if ! command -v cppcheck &> /dev/null; then
    echo "cppcheck not found. Installing cppcheck..."
    pip install cppcheck
else
    echo "cppcheck is already installed."
fi

# Activate venv for the current shell
source venv/bin/activate
exec "$SHELL"
