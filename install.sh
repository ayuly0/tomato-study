#!/usr/bin/env bash
# ==============================================================================
# Tomato Study — Production Installer for Linux & macOS
# "Focus. Study. Be Productive."
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"

echo -e "${BOLD}${CYAN}🍅 Tomato Study — Production Installer${RESET}"
echo -e "${CYAN}--------------------------------------------------${RESET}"

# Step 1: Detect Operating System
OS_TYPE="$(uname -s)"
echo -e "[1/5] Detecting platform: ${BOLD}${OS_TYPE}${RESET}..."

# Step 2: Check Python installation
echo -e "[2/5] Checking Python interpreter..."
PYTHON_BIN=""
for cmd in python3.13 python3.12 python3.11 python3.10 python3 python; do
    if command -v "$cmd" >/dev/null 2>&1; then
        PY_VER="$("$cmd" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)"
        MAJOR="$(echo "$PY_VER" | cut -d. -f1)"
        MINOR="$(echo "$PY_VER" | cut -d. -f2)"
        if [ "$MAJOR" -eq 3 ] && [ "$MINOR" -ge 10 ]; then
            PYTHON_BIN="$(command -v "$cmd")"
            echo -e "      Found Python ${GREEN}${PY_VER}${RESET} at: ${PYTHON_BIN}"
            break
        fi
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo -e "${RED}Error: Python 3.10+ is required but was not found.${RESET}"
    echo -e "Please install Python using your system package manager:"
    echo -e "  - Ubuntu/Debian:  sudo apt install python3 python3-pip python3-venv"
    echo -e "  - Fedora:         sudo dnf install python3 python3-pip"
    echo -e "  - Arch Linux:     sudo pacman -S python python-pip"
    echo -e "  - macOS:          brew install python3"
    exit 1
fi

# Step 3: Check for uv package manager or install it
echo -e "[3/5] Setting up package manager environment..."
USE_UV=false

if command -v uv >/dev/null 2>&1; then
    USE_UV=true
    UV_BIN="$(command -v uv)"
    echo -e "      Detected ${GREEN}uv${RESET} at: ${UV_BIN}"
elif [ -f "$HOME/.cargo/bin/uv" ]; then
    USE_UV=true
    UV_BIN="$HOME/.cargo/bin/uv"
    export PATH="$HOME/.cargo/bin:$PATH"
    echo -e "      Detected ${GREEN}uv${RESET} in ~/.cargo/bin"
elif [ -f "$HOME/.local/bin/uv" ]; then
    USE_UV=true
    UV_BIN="$HOME/.local/bin/uv"
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "      Detected ${GREEN}uv${RESET} in ~/.local/bin"
else
    echo -e "      ${YELLOW}uv${RESET} not detected. Attempting automatic standalone install..."
    if command -v curl >/dev/null 2>&1; then
        if curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then
            export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
            if command -v uv >/dev/null 2>&1; then
                USE_UV=true
                UV_BIN="$(command -v uv)"
                echo -e "      ${GREEN}uv successfully installed!${RESET}"
            fi
        fi
    fi
fi

# Step 4: Install Dependencies into virtual environment
echo -e "[4/5] Installing dependencies (PySide6 & Qt Quick dependencies)..."
if [ "$USE_UV" = true ]; then
    echo -e "      Creating environment and syncing with ${CYAN}uv${RESET}..."
    "$UV_BIN" venv .venv --python "$PYTHON_BIN"
    "$UV_BIN" pip install --upgrade "pyside6>=6.6.0" "pytest>=8.0.0"
else
    echo -e "      ${YELLOW}uv unavailable — falling back to standard venv + pip...${RESET}"
    if [ ! -d ".venv" ]; then
        "$PYTHON_BIN" -m venv .venv
    fi
    # shellcheck disable=SC1091
    source .venv/bin/activate
    pip install --upgrade pip >/dev/null 2>&1 || true
    pip install "pyside6>=6.6.0" "pytest>=8.0.0"
    deactivate
fi

# Step 5: Generate Launchers and Desktop Integration
echo -e "[5/5] Generating application launchers..."

# 1. Generate run.sh
cat << 'EOF' > "$APP_DIR/run.sh"
#!/usr/bin/env bash
set -e
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"

if [ -f "$HOME/.cargo/bin/uv" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
if [ -f "$HOME/.local/bin/uv" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$APP_DIR/.venv" ]; then
    # shellcheck disable=SC1091
    source "$APP_DIR/.venv/bin/activate"
    exec python "$APP_DIR/src/main.py" "$@"
elif command -v uv >/dev/null 2>&1; then
    exec uv run python "$APP_DIR/src/main.py" "$@"
else
    exec python3 "$APP_DIR/src/main.py" "$@"
fi
EOF
chmod +x "$APP_DIR/run.sh"

# 2. Linux Desktop Entry
if [ "$OS_TYPE" = "Linux" ]; then
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    ICON_PATH="$APP_DIR/assets/tomato.svg"
    if [ ! -f "$ICON_PATH" ]; then
        ICON_PATH="$APP_DIR/ui/volume-up.svg"
    fi
    
    DESKTOP_FILE="$DESKTOP_DIR/tomato-study.desktop"
    cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=Tomato Study
GenericName=Focus & Pomodoro Timer
Comment=Beautiful Pomodoro and Flowtime focus timer with lo-fi study stream
Exec=$APP_DIR/run.sh
Icon=$ICON_PATH
Terminal=false
Categories=Utility;Education;Office;
StartupNotify=true
EOF
    chmod +x "$DESKTOP_FILE"
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
    fi
    echo -e "      Desktop shortcut created: ${GREEN}$DESKTOP_FILE${RESET}"
fi

echo -e "\n${BOLD}${GREEN}✔ Installation completed successfully!${RESET}"
echo -e "${CYAN}--------------------------------------------------${RESET}"
echo -e "You can launch ${BOLD}Tomato Study${RESET} at any time using:"
echo -e "  ${BOLD}./run.sh${RESET}"
if [ "$USE_UV" = true ]; then
    echo -e "  ${BOLD}uv run python src/main.py${RESET}"
fi
echo -e "\nHotkeys in app:"
echo -e "  [Space] Play/Pause   [R] Reset    [S] Settings"
echo -e "  [Z]     Zen Mode     [P] Stream   [M] Mute Stream"
echo -e "${CYAN}--------------------------------------------------${RESET}"
