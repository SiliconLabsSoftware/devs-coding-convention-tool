@echo off
echo ----------------------------------------------------------
echo Deactivating Developer Services Project Virtual Environment
echo ----------------------------------------------------------

REM Check for the -h parameter
if "%1"=="-h" (
    echo Usage: deactivate.bat [-c]
    echo.
    echo Options:
    echo   -c    Clean virtual environment and remove installed programs
    exit /b 0
)
REM Check for the -c parameter
if "%1"=="-c" (
    echo Cleaning virtual environment and removing installed programs...

    REM Deactivate the virtual environment
    if exist "venv\Scripts\deactivate.bat" (
        call venv\Scripts\deactivate.bat
        echo Virtual environment deactivated.
    ) else (
        echo Virtual environment is not active.
    )

    REM Remove the virtual environment directory
    if exist "venv" (
        rmdir /s /q venv
        echo Virtual environment directory removed.
    ) else (
        echo Virtual environment directory does not exist.
    )

    REM Remove Uncrustify directory
    if exist "uncrustify" (
        rmdir /s /q uncrustify
        echo Uncrustify directory removed.
    ) else (
        echo Uncrustify directory does not exist.
    )

    REM Remove other installed programs if necessary
    REM Example: Remove Clang-tidy
    pip uninstall -y clang-tidy
    REM Example: Remove cppcheck
    pip uninstall -y cppcheck

    echo Cleaning completed.
    exit /b 0
)

REM Deactivate the virtual environment
if exist "venv\Scripts\deactivate.bat" (
    call venv\Scripts\deactivate.bat
    echo Virtual environment deactivated.
) else (
    echo Virtual environment is not active.
)

REM Add any additional project-specific processes to stop here
REM Example: Stop a specific service
REM net stop "ServiceName"

echo Project-specific processes stopped.
