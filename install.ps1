# ==============================================================================
# Tomato Study — Production Windows PowerShell Installer
# "Focus. Study. Be Productive."
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "   🍅 Tomato Study — Windows Automated Setup        " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Detect Python
Write-Host "[1/5] Checking Python installation..." -ForegroundColor Yellow
$pythonCmd = $null
foreach ($cmd in @("py -3", "python", "python3")) {
    try {
        $verStr = & cmd /c "$cmd -c `"import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')`"" 2>$null
        if ($verStr -match "^3\.(1[0-9]|[2-9][0-9])") {
            $pythonCmd = $cmd
            Write-Host "      Detected Python $verStr ($cmd)" -ForegroundColor Green
            break
        }
    } catch { }
}

if (-not $pythonCmd) {
    Write-Host "[ERROR] Python 3.10 or higher is required but was not found." -ForegroundColor Red
    Write-Host "Please install Python from https://www.python.org/downloads/ or via winget:" -ForegroundColor Yellow
    Write-Host "   winget install Python.Python.3.12" -ForegroundColor White
    Write-Host "(Be sure to check 'Add Python to PATH' during setup)" -ForegroundColor Yellow
    exit 1
}

# 2. Check for uv package manager
Write-Host "[2/5] Checking package manager (uv)..." -ForegroundColor Yellow
$hasUv = $false
if (Get-Command "uv" -ErrorAction SilentlyContinue) {
    $hasUv = $true
    Write-Host "      Found uv in PATH." -ForegroundColor Green
} elseif (Test-Path "$env:USERPROFILE\.cargo\bin\uv.exe") {
    $env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"
    $hasUv = $true
    Write-Host "      Found uv in ~/.cargo/bin." -ForegroundColor Green
} else {
    Write-Host "      uv not found. Attempting fast standalone bootstrap..." -ForegroundColor DarkYellow
    try {
        Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
        if (Test-Path "$env:USERPROFILE\.cargo\bin\uv.exe") {
            $env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"
            $hasUv = $true
            Write-Host "      uv installed successfully!" -ForegroundColor Green
        }
    } catch {
        Write-Host "      Could not bootstrap uv automatically; using standard python venv." -ForegroundColor DarkYellow
    }
}

# 3. Virtual Environment & Dependency Installation
Write-Host "[3/5] Installing dependencies (PySide6 & Qt Quick runtime)..." -ForegroundColor Yellow
$venvDir = Join-Path $appDir ".venv"

if ($hasUv) {
    Write-Host "      Configuring environment with uv..." -ForegroundColor Cyan
    & uv venv .venv
    & uv pip install --upgrade "pyside6>=6.6.0" "pytest>=8.0.0"
} else {
    Write-Host "      Configuring environment with standard Python venv & pip..." -ForegroundColor Cyan
    if (-not (Test-Path $venvDir)) {
        & cmd /c "$pythonCmd -m venv `"$venvDir`""
    }
    $venvPip = Join-Path $venvDir "Scripts\pip.exe"
    & "$venvPip" install --upgrade pip --quiet
    & "$venvPip" install "pyside6>=6.6.0" "pytest>=8.0.0"
}

# 4. Generate run.bat
Write-Host "[4/5] Creating run.bat launcher..." -ForegroundColor Yellow
$runBatContent = @"
@echo off
cd /d "%~dp0"
if exist ".venv\Scripts\pythonw.exe" (
    start "" ".venv\Scripts\pythonw.exe" "src\main.py" %*
) else if exist ".venv\Scripts\python.exe" (
    start "" ".venv\Scripts\python.exe" "src\main.py" %*
) else (
    uv run python "src\main.py" %*
)
"@
Set-Content -Path (Join-Path $appDir "run.bat") -Value $runBatContent -Encoding ASCII
Write-Host "      Created run.bat launcher." -ForegroundColor Green

# 5. Create Desktop & Start Menu Shortcuts
Write-Host "[5/5] Creating Windows Desktop and Start Menu shortcuts..." -ForegroundColor Yellow
try {
    $wshShell = New-Object -ComObject WScript.Shell
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Tomato Study.lnk"
    
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $appDir "run.bat"
    $shortcut.WorkingDirectory = $appDir
    $shortcut.Description = "Tomato Study - Focus & Pomodoro Timer"
    
    $iconPath = Join-Path $appDir "assets\tomato.ico"
    if (Test-Path $iconPath) {
        $shortcut.IconLocation = $iconPath
    }
    $shortcut.Save()
    Write-Host "      Desktop shortcut created: $shortcutPath" -ForegroundColor Green

    # Start Menu shortcut
    $startMenuPrograms = [System.Environment]::GetFolderPath("Programs")
    if (Test-Path $startMenuPrograms) {
        $startMenuShortcut = $wshShell.CreateShortcut((Join-Path $startMenuPrograms "Tomato Study.lnk"))
        $startMenuShortcut.TargetPath = Join-Path $appDir "run.bat"
        $startMenuShortcut.WorkingDirectory = $appDir
        $startMenuShortcut.Description = "Tomato Study - Focus & Pomodoro Timer"
        if (Test-Path $iconPath) {
            $startMenuShortcut.IconLocation = $iconPath
        }
        $startMenuShortcut.Save()
        Write-Host "      Start Menu shortcut created." -ForegroundColor Green
    }
} catch {
    Write-Host "      Note: Could not automatically register desktop shortcut ($($_.Exception.Message))." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "   ✔ Setup Completed Successfully!                   " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "You can now run Tomato Study by:" -ForegroundColor White
Write-Host "  1. Double-clicking 'Tomato Study' on your Desktop" -ForegroundColor Cyan
Write-Host "  2. Double-clicking 'run.bat' in this folder" -ForegroundColor Cyan
Write-Host "  3. Running: uv run python src/main.py" -ForegroundColor Cyan
Write-Host ""
Write-Host "Hotkeys inside the app:" -ForegroundColor White
Write-Host "  [Space] Play/Pause   [R] Reset    [S] Settings" -ForegroundColor Yellow
Write-Host "  [Z]     Zen Mode     [P] Stream   [M] Mute Stream" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
