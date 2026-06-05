import time
import math
from PySide6.QtCore import Slot, QTimer, QUrl, Qt
from PySide6.QtMultimedia import QSoundEffect
from audio import generate_chime_wav, generate_tick_wav, LateAudioStreamer
from constants import (
    CONFIG_FILE_NAME, CHIME_FILE_NAME, TICK_FILE_NAME, TIMER_TICK_INTERVAL_MS,
    SECONDS_IN_MINUTE, DEFAULT_WORK_MINUTES, UI_DIR
)
from presets import PresetsManager
from settings import SettingsManager
from timer_properties import TimerProperties

class TimerBackend(TimerProperties):
    def __init__(self, config_file=CONFIG_FILE_NAME, parent=None):
        super().__init__(parent)
        self._config_file = config_file
        self._view = None
        self._sound_effect = None
        self._tick_effect = None
        
        # Load presets
        self._presets_manager = PresetsManager()
        self._presets = self._presets_manager.presets
        self._presets_names = self._presets_manager.presets_names
        
        # Load configuration
        self._settings_manager = SettingsManager(self._config_file)
        self.load_settings()
        
        # Initialize streamer
        self._stream_status = "idle"
        self._song_title = ""
        self._streamer = LateAudioStreamer()
        self._streamer.set_volume(self._stream_volume)
        self._streamer.statusChanged.connect(self._on_stream_status_changed)
        self._streamer.songTitleChanged.connect(self._on_song_title_changed)
        self._streamer.set_enabled(self._stream_enabled)
        
        # Core state
        self._current_state = "work"
        self._is_running = False
        self._work_count = 0
        self._total_seconds_to_run = self._work_minutes * SECONDS_IN_MINUTE
        self._seconds_remaining = float(self._total_seconds_to_run)
        
        # Monotonic timers for sleep/drift resilience
        self._target_end_monotonic = 0.0
        self._paused_seconds_remaining = float(self._total_seconds_to_run)
        
        self._timer = QTimer(self)
        self._timer.setInterval(TIMER_TICK_INTERVAL_MS)
        self._timer.timeout.connect(self._on_tick)
        
        self.setup_sound()
        self.update_time_string()

    def set_view(self, view):
        self._view = view
        self.apply_always_on_top(self._always_on_top)

    def setup_sound(self):
        generate_chime_wav(CHIME_FILE_NAME)
        self._sound_effect = QSoundEffect(self)
        self._sound_effect.setSource(QUrl.fromLocalFile(CHIME_FILE_NAME))
        self._sound_effect.setVolume(self._alarm_volume)
        
        generate_tick_wav(TICK_FILE_NAME)
        self._tick_effect = QSoundEffect(self)
        self._tick_effect.setSource(QUrl.fromLocalFile(TICK_FILE_NAME))
        self._tick_effect.setVolume(self._alarm_volume * 0.4)

    def load_settings(self):
        settings = self._settings_manager.load()
        self._work_minutes = settings["work_minutes"]
        self._short_break_minutes = settings["short_break_minutes"]
        self._long_break_minutes = settings["long_break_minutes"]
        self._always_on_top = settings["always_on_top"]
        self._sound_enabled = settings["sound_enabled"]
        self._flash_enabled = settings["flash_enabled"]
        self._theme_color = settings["theme_color"]
        self._shader_damping = settings["shader_damping"]
        self._shader_speed = settings["shader_speed"]
        self._meteor_frequency = settings["meteor_frequency"]
        self._clock_theme = settings["clock_theme"]
        self._auto_start_breaks = settings["auto_start_breaks"]
        self._auto_start_work = settings["auto_start_work"]
        self._long_break_interval = settings["long_break_interval"]
        self._alarm_volume = settings["alarm_volume"]
        self._ticking_enabled = settings["ticking_enabled"]
        self._compact_width_threshold = settings["compact_width_threshold"]
        self._compact_height_threshold = settings["compact_height_threshold"]
        self._clock_scale = settings["clock_scale"]
        
        # Audio streaming configs
        self._stream_enabled = settings["stream_enabled"]
        self._stream_volume = settings["stream_volume"]
        
        # Preset configs
        self._active_preset = settings["active_preset"]
        self._timer_mode = settings["timer_mode"]
        
        # Keybind configs
        self._keybind_play_pause = settings["keybind_play_pause"]
        self._keybind_reset = settings["keybind_reset"]
        self._keybind_settings = settings["keybind_settings"]
        self._keybind_zen_mode = settings["keybind_zen_mode"]
        self._keybind_stream = settings["keybind_stream"]
        self._keybind_mute = settings["keybind_mute"]

    def save_settings_to_file(self):
        data = {
            "work_minutes": self._work_minutes,
            "short_break_minutes": self._short_break_minutes,
            "long_break_minutes": self._long_break_minutes,
            "always_on_top": self._always_on_top,
            "sound_enabled": self._sound_enabled,
            "flash_enabled": self._flash_enabled,
            "theme_color": self._theme_color,
            "shader_damping": self._shader_damping,
            "shader_speed": self._shader_speed,
            "meteor_frequency": self._meteor_frequency,
            "clock_theme": self._clock_theme,
            "auto_start_breaks": self._auto_start_breaks,
            "auto_start_work": self._auto_start_work,
            "long_break_interval": self._long_break_interval,
            "alarm_volume": self._alarm_volume,
            "ticking_enabled": self._ticking_enabled,
            "compact_width_threshold": self._compact_width_threshold,
            "compact_height_threshold": self._compact_height_threshold,
            "clock_scale": self._clock_scale,
            "stream_enabled": self._stream_enabled,
            "stream_volume": self._stream_volume,
            "active_preset": self._active_preset,
            "timer_mode": self._timer_mode,
            "keybind_play_pause": self._keybind_play_pause,
            "keybind_reset": self._keybind_reset,
            "keybind_settings": self._keybind_settings,
            "keybind_zen_mode": self._keybind_zen_mode,
            "keybind_stream": self._keybind_stream,
            "keybind_mute": self._keybind_mute
        }
        self._settings_manager.save(data)

    def apply_always_on_top(self, enabled):
        if not self._view:
            return
        flags = self._view.flags()
        if enabled:
            self._view.setFlags(flags | Qt.WindowStaysOnTopHint)
        else:
            self._view.setFlags(flags & ~Qt.WindowStaysOnTopHint)
        self._view.show()

    def update_time_string(self):
        if self._timer_mode == "flowtime" and self._current_state == "work":
            minutes = int(self._seconds_remaining) // SECONDS_IN_MINUTE
            seconds = int(self._seconds_remaining) % SECONDS_IN_MINUTE
        else:
            minutes = int(math.ceil(self._seconds_remaining)) // SECONDS_IN_MINUTE
            seconds = int(math.ceil(self._seconds_remaining)) % SECONDS_IN_MINUTE
            
        self.timeStringChanged.emit(f"{minutes:02d}:{seconds:02d}")
        
        progress = 0.0
        if self._total_seconds_to_run > 0:
            progress = max(0.0, min(1.0, self._seconds_remaining / self._total_seconds_to_run))
        elif self._timer_mode == "flowtime" and self._current_state == "work":
            progress = 1.0
        self.progressChanged.emit(progress)

    def _on_tick(self):
        if not self._is_running:
            return
        
        now = time.monotonic()
        
        if self._timer_mode == "flowtime" and self._current_state == "work":
            elapsed = now - self._target_end_monotonic
            
            # 24-hour limit check: if user walked away, reset and discard the session
            if elapsed >= 86400:
                self.reset()
                return
                
            old_sec = int(self._seconds_remaining)
            new_sec = int(elapsed)
            
            if old_sec != new_sec and new_sec > 0:
                if self._ticking_enabled and self._tick_effect:
                    self._tick_effect.play()
                    
            self._seconds_remaining = elapsed
            self.update_time_string()
        else:
            remaining = self._target_end_monotonic - now
            
            old_sec = int(math.ceil(self._seconds_remaining))
            new_sec = int(math.ceil(max(0.0, remaining)))
            
            if old_sec != new_sec and new_sec > 0:
                if self._ticking_enabled and self._tick_effect:
                    self._tick_effect.play()
                    
            if remaining <= 0:
                self._seconds_remaining = 0.0
                self.update_time_string()
                self._on_timer_complete()
            else:
                self._seconds_remaining = remaining
                self.update_time_string()

    def _on_timer_complete(self):
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        
        if self._sound_enabled and self._sound_effect:
            self._sound_effect.play()
        if self._flash_enabled:
            self.flashScreen.emit()
            
        self.timerFinished.emit()

        if self._current_state == "work":
            self._work_count += 1
            self.workCountChanged.emit(self._work_count)
            if self._work_count % self._long_break_interval == 0:
                self._current_state = "long_break"
                self._total_seconds_to_run = self._long_break_minutes * SECONDS_IN_MINUTE
            else:
                self._current_state = "short_break"
                self._total_seconds_to_run = self._short_break_minutes * SECONDS_IN_MINUTE
        else:
            self._current_state = "work"
            if self._timer_mode == "flowtime":
                self._total_seconds_to_run = 0
            else:
                self._total_seconds_to_run = self._work_minutes * SECONDS_IN_MINUTE
            
        if self._timer_mode == "flowtime" and self._current_state == "work":
            self._seconds_remaining = 0.0
            self._paused_seconds_remaining = 0.0
        else:
            self._seconds_remaining = float(self._total_seconds_to_run)
            self._paused_seconds_remaining = float(self._total_seconds_to_run)
            
        self.currentStateChanged.emit(self._current_state)
        self.update_time_string()
        
        should_auto_start = False
        if self._current_state in ("short_break", "long_break") and self._auto_start_breaks:
            should_auto_start = True
        elif self._current_state == "work" and self._auto_start_work:
            should_auto_start = True
            
        if should_auto_start:
            QTimer.singleShot(500, self.start)

    @Slot()
    def start(self):
        if self._is_running:
            return
        self._is_running = True
        self.isRunningChanged.emit(True)
        if self._timer_mode == "flowtime" and self._current_state == "work":
            self._target_end_monotonic = time.monotonic() - self._seconds_remaining
        else:
            self._target_end_monotonic = time.monotonic() + self._seconds_remaining
        self._timer.start()

    @Slot()
    def pause(self):
        if not self._is_running:
            return
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        if self._timer_mode == "flowtime" and self._current_state == "work":
            self._seconds_remaining = time.monotonic() - self._target_end_monotonic
        else:
            self._seconds_remaining = max(0.0, self._target_end_monotonic - time.monotonic())
        self._paused_seconds_remaining = self._seconds_remaining

    @Slot()
    def reset(self):
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        
        if self._current_state == "work":
            if self._timer_mode == "flowtime":
                self._total_seconds_to_run = 0
            else:
                self._total_seconds_to_run = self._work_minutes * SECONDS_IN_MINUTE
        elif self._current_state == "short_break":
            if self._timer_mode != "flowtime":
                self._total_seconds_to_run = self._short_break_minutes * SECONDS_IN_MINUTE
        else:
            if self._timer_mode != "flowtime":
                self._total_seconds_to_run = self._long_break_minutes * SECONDS_IN_MINUTE
            
        if self._timer_mode == "flowtime" and self._current_state == "work":
            self._seconds_remaining = 0.0
            self._paused_seconds_remaining = 0.0
        else:
            self._seconds_remaining = float(self._total_seconds_to_run)
            self._paused_seconds_remaining = float(self._total_seconds_to_run)
        self.update_time_string()

    @Slot(str, result=dict)
    def getPresetDetails(self, name):
        return self._presets_manager.get_preset_details(name)

    @Slot()
    def stopFlowtimeAndStartBreak(self):
        if self._timer_mode != "flowtime" or self._current_state != "work":
            return
            
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        
        elapsed_seconds = self._seconds_remaining
        elapsed_minutes = elapsed_seconds / 60.0
        
        if elapsed_minutes < 25.0:
            break_minutes = 5
        elif elapsed_minutes < 50.0:
            break_minutes = 8
        elif elapsed_minutes < 90.0:
            break_minutes = 10
        else:
            break_minutes = 20
            
        self._work_count += 1
        self.workCountChanged.emit(self._work_count)
        
        if self._work_count % self._long_break_interval == 0:
            self._current_state = "long_break"
        else:
            self._current_state = "short_break"
            
        self._total_seconds_to_run = break_minutes * SECONDS_IN_MINUTE
        self._seconds_remaining = float(self._total_seconds_to_run)
        self._paused_seconds_remaining = float(self._total_seconds_to_run)
        
        self.currentStateChanged.emit(self._current_state)
        self.update_time_string()
        self.start()

    @Slot()
    def skip(self):
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        
        if self._current_state == "work":
            if self._timer_mode == "flowtime":
                self.stopFlowtimeAndStartBreak()
                return
            else:
                self._work_count += 1
                self.workCountChanged.emit(self._work_count)
                if self._work_count % self._long_break_interval == 0:
                    self._current_state = "long_break"
                    self._total_seconds_to_run = self._long_break_minutes * SECONDS_IN_MINUTE
                else:
                    self._current_state = "short_break"
                    self._total_seconds_to_run = self._short_break_minutes * SECONDS_IN_MINUTE
        else:
            self._current_state = "work"
            if self._timer_mode == "flowtime":
                self._total_seconds_to_run = 0
            else:
                self._total_seconds_to_run = self._work_minutes * SECONDS_IN_MINUTE
                
        if self._timer_mode == "flowtime" and self._current_state == "work":
            self._seconds_remaining = 0.0
            self._paused_seconds_remaining = 0.0
        else:
            self._seconds_remaining = float(self._total_seconds_to_run)
            self._paused_seconds_remaining = float(self._total_seconds_to_run)
            
        self.currentStateChanged.emit(self._current_state)
        self.update_time_string()
        
        should_auto_start = False
        if self._current_state in ("short_break", "long_break") and self._auto_start_breaks:
            should_auto_start = True
        elif self._current_state == "work" and self._auto_start_work:
            should_auto_start = True
            
        if should_auto_start:
            self.start()

    @Slot()
    def resetAll(self):
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        
        self._current_state = "work"
        self._work_count = 0
        self.workCountChanged.emit(0)
        self.currentStateChanged.emit("work")
        
        if self._timer_mode == "flowtime":
            self._total_seconds_to_run = 0
            self._seconds_remaining = 0.0
            self._paused_seconds_remaining = 0.0
        else:
            self._total_seconds_to_run = self._work_minutes * SECONDS_IN_MINUTE
            self._seconds_remaining = float(self._total_seconds_to_run)
            self._paused_seconds_remaining = float(self._total_seconds_to_run)
            
        self.update_time_string()

    @Slot(int, int, int, bool, bool, bool, str, float, float, float, str, bool, bool, int, float, bool, bool, float, int, int, float, str, str)
    def updateSettings(self, work, short_break, long_break, aot, sound, flash, color, damping, shader_speed, meteor_freq, clock_theme="digital", auto_breaks=False, auto_work=False, lbi=4, volume=1.0, ticking=False, stream_enabled=False, stream_volume=0.5, compact_width=400, compact_height=250, clock_scale=1.0, active_preset="Pomodoro", timer_mode="countdown"):
        session_params_changed = (
            self._timer_mode != timer_mode or
            self._active_preset != active_preset or
            self._work_minutes != work or
            self._short_break_minutes != short_break or
            self._long_break_minutes != long_break or
            self._long_break_interval != lbi
        )
        
        # Check if we are mid-session
        is_mid_session = self._is_running or (
            self._current_state == "work" and (
                self._seconds_remaining > 0.0 if self._timer_mode == "flowtime" else self._seconds_remaining < self._work_minutes * SECONDS_IN_MINUTE
            )
        ) or (
            self._current_state == "short_break" and self._seconds_remaining < self._short_break_minutes * SECONDS_IN_MINUTE
        ) or (
            self._current_state == "long_break" and self._seconds_remaining < self._long_break_minutes * SECONDS_IN_MINUTE
        )

        self._work_minutes = work
        self._short_break_minutes = short_break
        self._long_break_minutes = long_break
        self._sound_enabled = sound
        self._flash_enabled = flash
        self._theme_color = color
        self._shader_damping = damping
        self._shader_speed = shader_speed
        self._meteor_frequency = meteor_freq
        self._clock_theme = clock_theme
        self._auto_start_breaks = auto_breaks
        self._auto_start_work = auto_work
        self._long_break_interval = lbi
        self._ticking_enabled = ticking
        self._compact_width_threshold = compact_width
        self._compact_height_threshold = compact_height
        self._clock_scale = clock_scale
        
        if self._alarm_volume != volume:
            self._alarm_volume = volume
            if self._sound_effect:
                self._sound_effect.setVolume(volume)
            if self._tick_effect:
                self._tick_effect.setVolume(volume * 0.4)
            self.alarmVolumeChanged.emit(volume)

        if self._always_on_top != aot:
            self._always_on_top = aot
            self.apply_always_on_top(aot)
            self.alwaysOnTopChanged.emit(aot)
            
        if self._stream_volume != stream_volume:
            self._stream_volume = stream_volume
            self._streamer.set_volume(stream_volume)
            self.streamVolumeChanged.emit(stream_volume)
            
        if self._stream_enabled != stream_enabled:
            self._stream_enabled = stream_enabled
            self._streamer.set_enabled(stream_enabled)
            self.streamEnabledChanged.emit(stream_enabled)
            self.streamMutedChanged.emit(self.streamMuted)
            
        if self._active_preset != active_preset:
            self._active_preset = active_preset
            self.activePresetChanged.emit(active_preset)
            
        if self._timer_mode != timer_mode:
            self._timer_mode = timer_mode
            self.timerModeChanged.emit(timer_mode)
            
        self.workMinutesChanged.emit(work)
        self.shortBreakMinutesChanged.emit(short_break)
        self.longBreakMinutesChanged.emit(long_break)
        self.soundEnabledChanged.emit(sound)
        self.flashEnabledChanged.emit(flash)
        self.themeColorChanged.emit(color)
        self.shaderDampingChanged.emit(damping)
        self.shaderSpeedChanged.emit(shader_speed)
        self.meteorFrequencyChanged.emit(meteor_freq)
        self.clockThemeChanged.emit(clock_theme)
        self.autoStartBreaksChanged.emit(auto_breaks)
        self.autoStartWorkChanged.emit(auto_work)
        self.longBreakIntervalChanged.emit(lbi)
        self.tickingEnabledChanged.emit(ticking)
        self.compactWidthThresholdChanged.emit(compact_width)
        self.compactHeightThresholdChanged.emit(compact_height)
        self.clockScaleChanged.emit(clock_scale)
        
        self.save_settings_to_file()
        
        if (session_params_changed and is_mid_session) or not self._is_running:
            self.reset()

    def cleanup(self):
        self._streamer.stop()
