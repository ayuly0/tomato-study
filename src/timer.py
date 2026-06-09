import time
import math
import os
from PySide6.QtCore import QObject, Signal, Property, Slot, QTimer, QUrl, Qt
from PySide6.QtMultimedia import QSoundEffect
from audio import generate_chime_wav, generate_tick_wav, LateAudioStreamer
from constants import (
    CONFIG_FILE_NAME, CHIME_FILE_NAME, TICK_FILE_NAME, TIMER_TICK_INTERVAL_MS,
    SECONDS_IN_MINUTE, DEFAULT_WORK_MINUTES, UI_DIR
)
from presets import PresetsManager
from settings import SettingsManager

class TimerBackend(QObject):
    # PySide signals to communicate state changes to QML
    workMinutesChanged = Signal(int)
    shortBreakMinutesChanged = Signal(int)
    longBreakMinutesChanged = Signal(int)
    alwaysOnTopChanged = Signal(bool)
    soundEnabledChanged = Signal(bool)
    flashEnabledChanged = Signal(bool)
    themeColorChanged = Signal(str)
    shaderDampingChanged = Signal(float)
    shaderSpeedChanged = Signal(float)
    meteorFrequencyChanged = Signal(float)
    clockThemeChanged = Signal(str)
    autoStartBreaksChanged = Signal(bool)
    autoStartWorkChanged = Signal(bool)
    longBreakIntervalChanged = Signal(int)
    alarmVolumeChanged = Signal(float)
    tickingEnabledChanged = Signal(bool)
    compactWidthThresholdChanged = Signal(int)
    compactHeightThresholdChanged = Signal(int)
    clockScaleChanged = Signal(float)
    
    # late.sh streaming signals
    streamEnabledChanged = Signal(bool)
    streamVolumeChanged = Signal(float)
    streamStatusChanged = Signal(str)
    songTitleChanged = Signal(str)
    streamMutedChanged = Signal(bool)
    
    # Keyboard shortcut keybinds signals
    keybindPlayPauseChanged = Signal(str)
    keybindResetChanged = Signal(str)
    keybindSettingsChanged = Signal(str)
    keybindZenModeChanged = Signal(str)
    keybindStreamChanged = Signal(str)
    keybindMuteChanged = Signal(str)
    
    # Timer state signals
    timeStringChanged = Signal(str)
    progressChanged = Signal(float)
    currentStateChanged = Signal(str)
    isRunningChanged = Signal(bool)
    workCountChanged = Signal(int)
    
    timerFinished = Signal()
    flashScreen = Signal()
    activePresetChanged = Signal(str)
    timerModeChanged = Signal(str)
    presetsListChanged = Signal(list)

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

    @property
    def _properties_map(self):
        """Map QML property names to their corresponding internal attributes, signals, and type casters."""
        return {
            "workMinutes": ("_work_minutes", self.workMinutesChanged, int),
            "shortBreakMinutes": ("_short_break_minutes", self.shortBreakMinutesChanged, int),
            "longBreakMinutes": ("_long_break_minutes", self.longBreakMinutesChanged, int),
            "alwaysOnTop": ("_always_on_top", self.alwaysOnTopChanged, bool),
            "soundEnabled": ("_sound_enabled", self.soundEnabledChanged, bool),
            "flashEnabled": ("_flash_enabled", self.flashEnabledChanged, bool),
            "themeColor": ("_theme_color", self.themeColorChanged, str),
            "shaderDamping": ("_shader_damping", self.shaderDampingChanged, float),
            "shaderSpeed": ("_shader_speed", self.shaderSpeedChanged, float),
            "meteorFrequency": ("_meteor_frequency", self.meteorFrequencyChanged, float),
            "clockTheme": ("_clock_theme", self.clockThemeChanged, str),
            "autoStartBreaks": ("_auto_start_breaks", self.autoStartBreaksChanged, bool),
            "autoStartWork": ("_auto_start_work", self.autoStartWorkChanged, bool),
            "longBreakInterval": ("_long_break_interval", self.longBreakIntervalChanged, int),
            "alarmVolume": ("_alarm_volume", self.alarmVolumeChanged, float),
            "tickingEnabled": ("_ticking_enabled", self.tickingEnabledChanged, bool),
            "compactWidthThreshold": ("_compact_width_threshold", self.compactWidthThresholdChanged, int),
            "compactHeightThreshold": ("_compact_height_threshold", self.compactHeightThresholdChanged, int),
            "clockScale": ("_clock_scale", self.clockScaleChanged, float),
            "streamEnabled": ("_stream_enabled", self.streamEnabledChanged, bool),
            "streamVolume": ("_stream_volume", self.streamVolumeChanged, float),
            "activePreset": ("_active_preset", self.activePresetChanged, str),
            "timerMode": ("_timer_mode", self.timerModeChanged, str),
        }

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
            
            # 24-hour limit check: if user walked away, reset and discard session
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

    @Slot(dict)
    def updateSettings(self, settings_dict):
        # 1. Determine if session configuration parameters have changed
        session_keys = {"timerMode", "activePreset", "workMinutes", "shortBreakMinutes", "longBreakMinutes", "longBreakInterval"}
        session_params_changed = any(
            key in settings_dict and getattr(self, self._properties_map[key][0]) != self._properties_map[key][2](settings_dict[key])
            for key in session_keys
        )
        
        # 2. Determine if we are mid-session to decide if a reset is needed (before applying changes)
        if self._current_state == "work" and self._timer_mode == "flowtime":
            is_mid_session = self._seconds_remaining > 0.0
        else:
            is_mid_session = self._seconds_remaining < self._total_seconds_to_run

        # 3. Apply settings dynamically
        for key, val in settings_dict.items():
            if key in self._properties_map:
                attr, signal, caster = self._properties_map[key]
                casted_val = caster(val)
                if getattr(self, attr) != casted_val:
                    setattr(self, attr, casted_val)
                    signal.emit(casted_val)
                    
                    # Apply specific side effects
                    if key == "alarmVolume":
                        if self._sound_effect:
                            self._sound_effect.setVolume(casted_val)
                        if self._tick_effect:
                            self._tick_effect.setVolume(casted_val * 0.4)
                    elif key == "alwaysOnTop":
                        self.apply_always_on_top(casted_val)
                    elif key == "streamVolume":
                        self._streamer.set_volume(casted_val)
                    elif key == "streamEnabled":
                        self._streamer.set_enabled(casted_val)
                        self.streamMutedChanged.emit(self.streamMuted)
                        
        self.save_settings_to_file()
        
        if (session_params_changed and is_mid_session) or not self._is_running:
            self.reset()

    @Slot(str, str, str, str, str, str)
    def updateKeybinds(self, play_pause, reset, settings, zen_mode, stream, mute):
        self._keybind_play_pause = play_pause
        self._keybind_reset = reset
        self._keybind_settings = settings
        self._keybind_zen_mode = zen_mode
        self._keybind_stream = stream
        self._keybind_mute = mute
        
        self.keybindPlayPauseChanged.emit(play_pause)
        self.keybindResetChanged.emit(reset)
        self.keybindSettingsChanged.emit(settings)
        self.keybindZenModeChanged.emit(zen_mode)
        self.keybindStreamChanged.emit(stream)
        self.keybindMuteChanged.emit(mute)
        
        self.save_settings_to_file()

    @Slot(float)
    def setAlarmVolume(self, volume):
        self._alarm_volume = volume
        if self._sound_effect:
            self._sound_effect.setVolume(volume)
        if self._tick_effect:
            self._tick_effect.setVolume(volume * 0.4)
        self.alarmVolumeChanged.emit(volume)
        self.save_settings_to_file()

    @Slot()
    def toggleStream(self):
        self._streamer.toggle_mute()
        if not self._stream_enabled:
            self._stream_enabled = True
            self.streamEnabledChanged.emit(True)
        self.streamMutedChanged.emit(self.streamMuted)
        self.save_settings_to_file()

    @Slot(float)
    def setStreamVolume(self, volume):
        self._stream_volume = volume
        self._streamer.set_volume(volume)
        self.streamVolumeChanged.emit(volume)
        self.save_settings_to_file()

    def _on_stream_status_changed(self, status):
        if self._stream_status != status:
            self._stream_status = status
            self.streamStatusChanged.emit(status)

    def _on_song_title_changed(self, title):
        if self._song_title != title:
            self._song_title = title
            self.songTitleChanged.emit(title)

    def cleanup(self):
        self._streamer.stop()

    # Qt Properties exposed to QML Engine
    @Property(int, notify=workMinutesChanged)
    def workMinutes(self): return self._work_minutes

    @Property(int, notify=shortBreakMinutesChanged)
    def shortBreakMinutes(self): return self._short_break_minutes

    @Property(int, notify=longBreakMinutesChanged)
    def longBreakMinutes(self): return self._long_break_minutes

    @Property(bool, notify=alwaysOnTopChanged)
    def alwaysOnTop(self): return self._always_on_top

    @Property(bool, notify=soundEnabledChanged)
    def soundEnabled(self): return self._sound_enabled

    @Property(bool, notify=flashEnabledChanged)
    def flashEnabled(self): return self._flash_enabled

    @Property(str, notify=themeColorChanged)
    def themeColor(self): return self._theme_color

    @Property(float, notify=shaderDampingChanged)
    def shaderDamping(self): return self._shader_damping

    @Property(float, notify=shaderSpeedChanged)
    def shaderSpeed(self): return self._shader_speed

    @Property(float, notify=meteorFrequencyChanged)
    def meteorFrequency(self): return self._meteor_frequency

    @Property(str, notify=clockThemeChanged)
    def clockTheme(self): return self._clock_theme

    @Property(bool, notify=autoStartBreaksChanged)
    def autoStartBreaks(self): return self._auto_start_breaks

    @Property(bool, notify=autoStartWorkChanged)
    def autoStartWork(self): return self._auto_start_work

    @Property(int, notify=longBreakIntervalChanged)
    def longBreakInterval(self): return self._long_break_interval

    @Property(float, notify=alarmVolumeChanged)
    def alarmVolume(self): return self._alarm_volume

    @Property(bool, notify=tickingEnabledChanged)
    def tickingEnabled(self): return self._ticking_enabled

    @Property(int, notify=compactWidthThresholdChanged)
    def compactWidthThreshold(self): return self._compact_width_threshold

    @Property(int, notify=compactHeightThresholdChanged)
    def compactHeightThreshold(self): return self._compact_height_threshold

    @Property(float, notify=clockScaleChanged)
    def clockScale(self): return self._clock_scale

    @Property(bool, notify=streamEnabledChanged)
    def streamEnabled(self): return self._stream_enabled

    @Property(bool, notify=streamMutedChanged)
    def streamMuted(self): return not self._stream_enabled or self._streamer._is_muted

    @Property(float, notify=streamVolumeChanged)
    def streamVolume(self): return self._stream_volume

    @Property(str, notify=streamStatusChanged)
    def streamStatus(self): return self._stream_status

    @Property(str, notify=songTitleChanged)
    def songTitle(self): return self._song_title

    @Property(str, notify=timeStringChanged)
    def timeString(self): 
        if self._timer_mode == "flowtime" and self._current_state == "work":
            m = int(self._seconds_remaining) // 60
            s = int(self._seconds_remaining) % 60
        else:
            m = int(math.ceil(self._seconds_remaining)) // 60
            s = int(math.ceil(self._seconds_remaining)) % 60
        return f"{m:02d}:{s:02d}"

    @Property(float, notify=progressChanged)
    def progress(self):
        if self._total_seconds_to_run <= 0:
            if self._timer_mode == "flowtime" and self._current_state == "work":
                return 1.0
            return 0.0
        return max(0.0, min(1.0, self._seconds_remaining / self._total_seconds_to_run))

    @Property(str, notify=currentStateChanged)
    def currentState(self): return self._current_state

    @Property(bool, notify=isRunningChanged)
    def isRunning(self): return self._is_running

    @Property(int, notify=workCountChanged)
    def workCount(self): return self._work_count

    @Property(str, notify=activePresetChanged)
    def activePreset(self): return self._active_preset

    @Property(str, notify=timerModeChanged)
    def timerMode(self): return self._timer_mode

    @Property(list, notify=presetsListChanged)
    def presetsList(self): return self._presets_names

    @Property(str, notify=keybindPlayPauseChanged)
    def keybindPlayPause(self): return self._keybind_play_pause

    @Property(str, notify=keybindResetChanged)
    def keybindReset(self): return self._keybind_reset

    @Property(str, notify=keybindSettingsChanged)
    def keybindSettings(self): return self._keybind_settings

    @Property(str, notify=keybindZenModeChanged)
    def keybindZenMode(self): return self._keybind_zen_mode

    @Property(str, notify=keybindStreamChanged)
    def keybindStream(self): return self._keybind_stream

    @Property(str, notify=keybindMuteChanged)
    def keybindMute(self): return self._keybind_mute
