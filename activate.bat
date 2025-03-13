@echo off
echo --------------------------------------------------------------
echo Activating Developer Services Project Virtual Environment
echo This script will install a pre-commit hook to check code style.
echo Use it when you want to develop or contribute to the project.
echo For build environment setup, Dockerfile is recommended.
echo --------------------------------------------------------------

REM Check if the script was called from a subfolder
for %%I in ("%~dp0") do set "PARENT_DIR=%%~dpI"
if "%PARENT_DIR%"=="%cd%\" (
    cd ..
)

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Python not found. Please install Python 3.8 or later.
    echo Installing Python...
    curl -o python-installer.exe https://www.python.org/ftp/python/3.9.7/python-3.9.7-amd64.exe
    start /wait python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    del python-installer.exe
    exit /b 1
) else (
    echo Python is installed.
)

REM Check if the virtual environment directory exists
if not exist "venv" (
    echo Virtual environment not found. Creating one...
    python -m venv venv
)

REM Activate the virtual environment
echo Activating the virtual environment...
call venv\Scripts\activate.bat
echo Virtual environment activated.

REM Check if pre-commit is already installed
pip show pre-commit >nul 2>&1
if errorlevel 1 (
    echo pre-commit not found. Installing pre-commit...
    pip install pre-commit
) else (
    echo pre-commit is already installed.
)

REM Initialize pre-commit
echo Initializing pre-commit...
pre-commit install

REM Check if CMake is already installed
cmake --version >nul 2>&1
if errorlevel 1 (
    echo CMake not found. Installing latest CMake...
    pip install cmake
) else (
    echo CMake is already installed.
)

REM Check if Ninja is already installed
ninja --version >nul 2>&1
if errorlevel 1 (
    echo Ninja not found. Installing latest Ninja...
    pip install ninja
) else (
    echo Ninja is already installed.
)

REM Clone and compile Uncrustify 0.64
if not exist "uncrustify" (
    echo Uncrustify not found. Cloning Uncrustify...
    git clone -b uncrustify-0.64 --single-branch https://github.com/uncrustify/uncrustify.git
    if errorlevel 1 (
        echo Failed to clone Uncrustify repository. Exiting...
        exit /b 1
    )
    echo Compiling Uncrustify...
    cd uncrustify
    mkdir build
    cd build
    cmake --build .
    if errorlevel 1 (
        echo Failed to compile Uncrustify. Exiting...
        exit /b 1
    )
    cd ..
    cd ..
    echo Uncrustify cloned and compiled.
    echo Copying Uncrustify configuration file...
    copy uncrustify.cfg uncrustify\uncrustify.cfg
) else (
    echo Uncrustify is already cloned and compiled.
)
REM Install Clang-tidy
if not exist "clang-tidy" (
    echo Clang-tidy not found. Installing Clang-tidy...
    pip install clang-tidy
) else (
    echo Clang-tidy is already installed.
)

REM Install cppcheck
if not exist "cppcheck" (
    echo cppcheck not found. Installing cppcheck...
    pip install cppcheck
) else (
    echo cppcheck is already installed.
)
REM activate venv for the current shell
call venv\Scripts\activate.bat
cmd /k
