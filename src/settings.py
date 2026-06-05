import os
import json
from constants import (
    CONFIG_FILE_NAME, DEFAULT_WORK_MINUTES, DEFAULT_SHORT_BREAK_MINUTES,
    DEFAULT_LONG_BREAK_MINUTES, DEFAULT_ALWAYS_ON_TOP, DEFAULT_SOUND_ENABLED,
    DEFAULT_FLASH_ENABLED, DEFAULT_THEME_COLOR, DEFAULT_SHADER_DAMPING,
    DEFAULT_SHADER_SPEED, DEFAULT_METEOR_FREQUENCY, DEFAULT_LONG_BREAK_INTERVAL,
    DEFAULT_ALARM_VOLUME, DEFAULT_STREAM_VOLUME, DEFAULT_COMPACT_WIDTH_THRESHOLD,
    DEFAULT_COMPACT_HEIGHT_THRESHOLD, DEFAULT_CLOCK_SCALE
)

class SettingsManager:
    """Handles loading, defaults fallback, and saving of application settings."""
    def __init__(self, config_file=CONFIG_FILE_NAME):
        self.config_file = config_file
        
    def load(self) -> dict:
        if self.config_file and os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    data = json.load(f)
                return {
                    "work_minutes": int(data.get("work_minutes", DEFAULT_WORK_MINUTES)),
                    "short_break_minutes": int(data.get("short_break_minutes", DEFAULT_SHORT_BREAK_MINUTES)),
                    "long_break_minutes": int(data.get("long_break_minutes", DEFAULT_LONG_BREAK_MINUTES)),
                    "always_on_top": bool(data.get("always_on_top", DEFAULT_ALWAYS_ON_TOP)),
                    "sound_enabled": bool(data.get("sound_enabled", DEFAULT_SOUND_ENABLED)),
                    "flash_enabled": bool(data.get("flash_enabled", DEFAULT_FLASH_ENABLED)),
                    "theme_color": str(data.get("theme_color", DEFAULT_THEME_COLOR)),
                    "shader_damping": float(data.get("shader_damping", DEFAULT_SHADER_DAMPING)),
                    "shader_speed": float(data.get("shader_speed", DEFAULT_SHADER_SPEED)),
                    "meteor_frequency": float(data.get("meteor_frequency", DEFAULT_METEOR_FREQUENCY)),
                    "clock_theme": str(data.get("clock_theme", "flip")),
                    "auto_start_breaks": bool(data.get("auto_start_breaks", False)),
                    "auto_start_work": bool(data.get("auto_start_work", False)),
                    "long_break_interval": int(data.get("long_break_interval", DEFAULT_LONG_BREAK_INTERVAL)),
                    "alarm_volume": float(data.get("alarm_volume", DEFAULT_ALARM_VOLUME)),
                    "ticking_enabled": bool(data.get("ticking_enabled", False)),
                    "compact_width_threshold": int(data.get("compact_width_threshold", DEFAULT_COMPACT_WIDTH_THRESHOLD)),
                    "compact_height_threshold": int(data.get("compact_height_threshold", DEFAULT_COMPACT_HEIGHT_THRESHOLD)),
                    "clock_scale": float(data.get("clock_scale", DEFAULT_CLOCK_SCALE)),
                    "stream_enabled": bool(data.get("stream_enabled", False)),
                    "stream_volume": float(data.get("stream_volume", DEFAULT_STREAM_VOLUME)),
                    "active_preset": str(data.get("active_preset", "Pomodoro")),
                    "timer_mode": str(data.get("timer_mode", "countdown")),
                    "keybind_play_pause": str(data.get("keybind_play_pause", "Space")),
                    "keybind_reset": str(data.get("keybind_reset", "R")),
                    "keybind_settings": str(data.get("keybind_settings", "S")),
                    "keybind_zen_mode": str(data.get("keybind_zen_mode", "Z")),
                    "keybind_stream": str(data.get("keybind_stream", "P")),
                    "keybind_mute": str(data.get("keybind_mute", "M"))
                }
            except Exception:
                pass
                
        # Default fallbacks
        defaults = {
            "work_minutes": DEFAULT_WORK_MINUTES,
            "short_break_minutes": DEFAULT_SHORT_BREAK_MINUTES,
            "long_break_minutes": DEFAULT_LONG_BREAK_MINUTES,
            "always_on_top": DEFAULT_ALWAYS_ON_TOP,
            "sound_enabled": DEFAULT_SOUND_ENABLED,
            "flash_enabled": DEFAULT_FLASH_ENABLED,
            "theme_color": DEFAULT_THEME_COLOR,
            "shader_damping": DEFAULT_SHADER_DAMPING,
            "shader_speed": DEFAULT_SHADER_SPEED,
            "meteor_frequency": DEFAULT_METEOR_FREQUENCY,
            "clock_theme": "flip",
            "auto_start_breaks": False,
            "auto_start_work": False,
            "long_break_interval": DEFAULT_LONG_BREAK_INTERVAL,
            "alarm_volume": DEFAULT_ALARM_VOLUME,
            "ticking_enabled": False,
            "compact_width_threshold": DEFAULT_COMPACT_WIDTH_THRESHOLD,
            "compact_height_threshold": DEFAULT_COMPACT_HEIGHT_THRESHOLD,
            "clock_scale": DEFAULT_CLOCK_SCALE,
            "stream_enabled": False,
            "stream_volume": DEFAULT_STREAM_VOLUME,
            "active_preset": "Pomodoro",
            "timer_mode": "countdown",
            "keybind_play_pause": "Space",
            "keybind_reset": "R",
            "keybind_settings": "S",
            "keybind_zen_mode": "Z",
            "keybind_stream": "P",
            "keybind_mute": "M"
        }
        self.save(defaults)
        return defaults

    def save(self, settings_dict: dict):
        if not self.config_file:
            return
        try:
            with open(self.config_file, 'w') as f:
                json.dump(settings_dict, f, indent=2)
        except IOError:
            pass
