import os
import json
from constants import (
    CONFIG_FILE_NAME, DEFAULT_WORK_MINUTES, DEFAULT_SHORT_BREAK_MINUTES,
    DEFAULT_LONG_BREAK_MINUTES, DEFAULT_ALWAYS_ON_TOP, DEFAULT_SOUND_ENABLED,
    DEFAULT_FLASH_ENABLED, DEFAULT_THEME_COLOR, DEFAULT_SHADER_DAMPING,
    DEFAULT_SHADER_SPEED, DEFAULT_METEOR_FREQUENCY, DEFAULT_LONG_BREAK_INTERVAL,
    DEFAULT_ALARM_VOLUME, DEFAULT_STREAM_VOLUME, DEFAULT_COMPACT_WIDTH_THRESHOLD,
    DEFAULT_COMPACT_HEIGHT_THRESHOLD, DEFAULT_CLOCK_SCALE,
    DEFAULT_STRICT_FOCUS_ENABLED, DEFAULT_PRIVACY_LOCK_ENABLED,
    DEFAULT_ENCRYPT_STORAGE, DEFAULT_BLOCKED_DOMAINS
)
from security import DataCryptor

class SettingsManager:
    """Handles loading, defaults fallback, and AES-256 encrypted saving of application settings."""
    def __init__(self, config_file=CONFIG_FILE_NAME):
        self.config_file = config_file
        self._last_saved_json = None
        self._last_saved_encrypted = None
        
    def load(self) -> dict:
        if self.config_file and os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'rb') as f:
                    raw_bytes = f.read()

                if DataCryptor.is_encrypted(raw_bytes):
                    decrypted_text = DataCryptor.decrypt(raw_bytes)
                    data = json.loads(decrypted_text)
                else:
                    data = json.loads(raw_bytes.decode('utf-8'))

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
                    "keybind_mute": str(data.get("keybind_mute", "M")),
                    "strict_focus_enabled": bool(data.get("strict_focus_enabled", DEFAULT_STRICT_FOCUS_ENABLED)),
                    "privacy_lock_enabled": bool(data.get("privacy_lock_enabled", DEFAULT_PRIVACY_LOCK_ENABLED)),
                    "encrypt_storage": bool(data.get("encrypt_storage", DEFAULT_ENCRYPT_STORAGE)),
                    "blocked_domains": list(data.get("blocked_domains", DEFAULT_BLOCKED_DOMAINS))
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
            "keybind_mute": "M",
            "strict_focus_enabled": DEFAULT_STRICT_FOCUS_ENABLED,
            "privacy_lock_enabled": DEFAULT_PRIVACY_LOCK_ENABLED,
            "encrypt_storage": DEFAULT_ENCRYPT_STORAGE,
            "blocked_domains": DEFAULT_BLOCKED_DOMAINS
        }
        self.save(defaults)
        return defaults

    def save(self, settings_dict: dict):
        if not self.config_file:
            return
        try:
            encrypt = bool(settings_dict.get("encrypt_storage", False))
            json_text = json.dumps(settings_dict, indent=2, sort_keys=True)
            
            # Avoid redundant encryption / disk I/O if unchanged and file exists
            if (self._last_saved_json == json_text and 
                self._last_saved_encrypted == encrypt and 
                os.path.exists(self.config_file)):
                return

            if encrypt:
                encrypted_bytes = DataCryptor.encrypt(json_text)
                with open(self.config_file, 'wb') as f:
                    f.write(encrypted_bytes)
            else:
                with open(self.config_file, 'w', encoding='utf-8') as f:
                    f.write(json_text)
                    
            self._last_saved_json = json_text
            self._last_saved_encrypted = encrypt
        except IOError:
            pass
