@echo off
cd /d "%~dp0"
if exist ".venv\Scripts\pythonw.exe" (
    start "" ".venv\Scripts\pythonw.exe" "src\main.py" %*
) else if exist ".venv\Scripts\python.exe" (
    start "" ".venv\Scripts\python.exe" "src\main.py" %*
) else (
    uv run python "src\main.py" %*
)
