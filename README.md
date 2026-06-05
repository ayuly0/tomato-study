# Tomato Study 🍅

Tomato Study is a beautiful, interactive Pomodoro timer built with **PySide6** and **Qt Quick (QML)**. It features a stunning 2.5D flip clock animation, interactive background shaders, customizable settings, global hotkeys, and integration with the late.sh lo-fi vibe radio stream.

Currently, this application has only been tested on **Linux**.

---

## Previews

### Main Application
![Tomato Study UI Preview](assets/main_preview.png)

### Settings Panel
![Tomato Study Settings Preview](assets/settings_preview.png)

---

## Features

- **Split-Card Flip Clock & Digital Clock**: Sleek and satisfying card flip animations and a clean digital layout.
- **Timer Presets**: Switch between built-in presets like traditional Pomodoro and Flowtime, or create your own custom intervals.
- **Flowtime Mode**: A flexible timer mode that counts up, allowing you to focus as long as you want while automatically calculating appropriate break times.
- **Compact Mode**: Scale down the UI and adjust dimensions for a minimal footprint on your screen.
- **Study Stream Integration**: Stream background study music directly from the `late.sh` vibe radio with a built-in volume slider and mute toggle.
- **Zen Mode**: Double-click the background (or press `Z`) to hide all UI elements and cursor for distraction-free focus.
- **Interactive Background**: High-performance fragment shaders rendering drifting stars, shooting meteors, and trail effects that react to your mouse.
- **Customizable Pomodoro Intervals**: Configure work time, short breaks, long breaks, and auto-start preferences.
- **Configurable Hotkeys**: Global shortcuts for playing/pausing, resetting, toggling Zen mode, muting/unmuting, and opening settings.
- **Always on Top**: Pin the timer above other windows.

---

## Setup & Running Instructions

The project uses [uv](https://github.com/astral-sh/uv) to manage Python dependencies automatically.

### Prerequisites

Make sure you have `uv` installed. If you don't have it, you can install it using:

```bash
# On Linux / macOS
curl -LsSf https://astral-sh/uv/install.sh | sh
```

### Running the App

To automatically install the required dependencies (such as `PySide6`) and launch the app, simply run:

```bash
uv run python src/main.py
```

---

## Shortcuts & Controls

- **Double-click background**: Toggle Zen Mode.
- **Space** (Default): Play / Pause timer.
- **R** (Default): Reset timer.
- **S** (Default): Open Settings Panel.
- **Z** (Default): Toggle Zen Mode.
- **P** (Default): Toggle background music stream.
- **M** (Default): Mute / Unmute music stream.

*(You can configure all of these keybindings inside the **Settings** panel)*

---

## Credits

- **Study Stream**: Lo-fi background music stream is powered by [late.sh](https://late.sh).
