@echo off
REM ==============================================================================
REM Tomato Study — Production Windows Installer Launcher
REM ==============================================================================
title Tomato Study - Installer
color 0B
echo.
echo ===================================================
echo     Tomato Study - Windows Automated Installer
echo ===================================================
echo.

cd /d "%~dp0"

REM Prefer running modern PowerShell installer if PowerShell is available
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if %ERRORLEVEL% EQU 0 goto :success

echo.
echo [!] PowerShell script completed with code %ERRORLEVEL% or was restricted.
echo Trying standard command prompt fallback setup...
echo.

where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python was not found in PATH!
    echo Please install Python 3.10+ from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b 1
)

if not exist ".venv" (
    echo [*] Creating virtual environment (.venv)...
    python -m venv .venv
)

echo [*] Installing dependencies (PySide6)...
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install "pyside6>=6.6.0" "pytest>=8.0.0"

:success
echo.
echo ===================================================
echo [SUCCESS] Setup complete! Double-click run.bat to start.
echo ===================================================
echo.
pause
