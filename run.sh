#!/usr/bin/env bash
# ==============================================================================
# Tomato Study — Production Runner (Linux & macOS)
# ==============================================================================
set -e

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"

# Include user binary paths if not in PATH
for p in "$HOME/.cargo/bin" "$HOME/.local/bin"; do
    if [ -d "$p" ] && [[ ":$PATH:" != *":$p:"* ]]; then
        export PATH="$p:$PATH"
    fi
done

# Priority 1: Virtual environment inside project
if [ -f "$APP_DIR/.venv/bin/python" ]; then
    exec "$APP_DIR/.venv/bin/python" "$APP_DIR/src/main.py" "$@"
fi

# Priority 2: Astral uv runner
if command -v uv >/dev/null 2>&1; then
    exec uv run python "$APP_DIR/src/main.py" "$@"
fi

# Priority 3: System python3 with fallback notice
if command -v python3 >/dev/null 2>&1; then
    exec python3 "$APP_DIR/src/main.py" "$@"
fi

echo "Error: Could not locate Python or virtual environment."
echo "Please run ./install.sh first to set up Tomato Study."
exit 1
