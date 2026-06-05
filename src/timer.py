import os
import json
import time
import math
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, QUrl, Qt
from PySide6.QtMultimedia import QSoundEffect
from audio import generate_chime_wav, generate_tick_wav, LateAudioStreamer

# Named constants to prevent magic numbers
DEFAULT_WORK_MINUTES = 25
DEFAULT_SHORT_BREAK_MINUTES = 5
DEFAULT_LONG_BREAK_MINUTES = 15
DEFAULT_ALWAYS_ON_TOP = True
DEFAULT_SOUND_ENABLED = True
DEFAULT_FLASH_ENABLED = True
DEFAULT_THEME_COLOR = "#ff4d4d"
DEFAULT_SHADER_DAMPING = 0.05
DEFAULT_SHADER_SPEED = 0.015
DEFAULT_METEOR_FREQUENCY = 0.4
DEFAULT_LONG_BREAK_INTERVAL = 4
DEFAULT_ALARM_VOLUME = 1.0
DEFAULT_STREAM_VOLUME = 0.5
TIMER_TICK_INTERVAL_MS = 100
SECONDS_IN_MINUTE = 60

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SRC_DIR)
UI_DIR = os.path.join(PROJECT_DIR, "ui")
CONFIG_FILE_NAME = os.path.join(PROJECT_DIR, "config.json")
CHIME_FILE_NAME = os.path.join(UI_DIR, "chime.wav")
TICK_FILE_NAME = os.path.join(UI_DIR, "tick.wav")

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
    
    # late.sh streaming signals
    streamEnabledChanged = Signal(bool)
    streamVolumeChanged = Signal(float)
    streamStatusChanged = Signal(str)
    songTitleChanged = Signal(str)
    
    keybindPlayPauseChanged = Signal(str)
    keybindResetChanged = Signal(str)
    keybindSettingsChanged = Signal(str)
    keybindZenModeChanged = Signal(str)
    keybindStreamChanged = Signal(str)
    keybindMuteChanged = Signal(str)
    
    timeStringChanged = Signal(str)
    progressChanged = Signal(float)
    currentStateChanged = Signal(str)
    isRunningChanged = Signal(bool)
    workCountChanged = Signal(int)
    
    timerFinished = Signal()
    flashScreen = Signal()

    def __init__(self, config_file=CONFIG_FILE_NAME, parent=None):
        super().__init__(parent)
        self._config_file = config_file
        self._view = None
        self._sound_effect = None
        self._tick_effect = None
        
        # Load configuration
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
        if self._config_file and os.path.exists(self._config_file):
            try:
                with open(self._config_file, 'r') as f:
                    data = json.load(f)
                self._work_minutes = int(data.get("work_minutes", DEFAULT_WORK_MINUTES))
                self._short_break_minutes = int(data.get("short_break_minutes", DEFAULT_SHORT_BREAK_MINUTES))
                self._long_break_minutes = int(data.get("long_break_minutes", DEFAULT_LONG_BREAK_MINUTES))
                self._always_on_top = bool(data.get("always_on_top", DEFAULT_ALWAYS_ON_TOP))
                self._sound_enabled = bool(data.get("sound_enabled", DEFAULT_SOUND_ENABLED))
                self._flash_enabled = bool(data.get("flash_enabled", DEFAULT_FLASH_ENABLED))
                self._theme_color = str(data.get("theme_color", DEFAULT_THEME_COLOR))
                self._shader_damping = float(data.get("shader_damping", DEFAULT_SHADER_DAMPING))
                self._shader_speed = float(data.get("shader_speed", DEFAULT_SHADER_SPEED))
                self._meteor_frequency = float(data.get("meteor_frequency", DEFAULT_METEOR_FREQUENCY))
                self._clock_theme = str(data.get("clock_theme", "flip"))
                self._auto_start_breaks = bool(data.get("auto_start_breaks", False))
                self._auto_start_work = bool(data.get("auto_start_work", False))
                self._long_break_interval = int(data.get("long_break_interval", DEFAULT_LONG_BREAK_INTERVAL))
                self._alarm_volume = float(data.get("alarm_volume", DEFAULT_ALARM_VOLUME))
                self._ticking_enabled = bool(data.get("ticking_enabled", False))
                
                # Audio streaming configs
                self._stream_enabled = bool(data.get("stream_enabled", False))
                self._stream_volume = float(data.get("stream_volume", DEFAULT_STREAM_VOLUME))
                
                # Keybind configs
                self._keybind_play_pause = str(data.get("keybind_play_pause", "Space"))
                self._keybind_reset = str(data.get("keybind_reset", "R"))
                self._keybind_settings = str(data.get("keybind_settings", "S"))
                self._keybind_zen_mode = str(data.get("keybind_zen_mode", "Z"))
                self._keybind_stream = str(data.get("keybind_stream", "P"))
                self._keybind_mute = str(data.get("keybind_mute", "M"))
                return
            except Exception:
                pass
                
        # Defaults
        self._work_minutes = DEFAULT_WORK_MINUTES
        self._short_break_minutes = DEFAULT_SHORT_BREAK_MINUTES
        self._long_break_minutes = DEFAULT_LONG_BREAK_MINUTES
        self._always_on_top = DEFAULT_ALWAYS_ON_TOP
        self._sound_enabled = DEFAULT_SOUND_ENABLED
        self._flash_enabled = DEFAULT_FLASH_ENABLED
        self._theme_color = DEFAULT_THEME_COLOR
        self._shader_damping = DEFAULT_SHADER_DAMPING
        self._shader_speed = DEFAULT_SHADER_SPEED
        self._meteor_frequency = DEFAULT_METEOR_FREQUENCY
        self._clock_theme = "flip"
        self._auto_start_breaks = False
        self._auto_start_work = False
        self._long_break_interval = DEFAULT_LONG_BREAK_INTERVAL
        self._alarm_volume = DEFAULT_ALARM_VOLUME
        self._ticking_enabled = False
        self._stream_enabled = False
        self._stream_volume = DEFAULT_STREAM_VOLUME
        
        self._keybind_play_pause = "Space"
        self._keybind_reset = "R"
        self._keybind_settings = "S"
        self._keybind_zen_mode = "Z"
        self._keybind_stream = "P"
        self._keybind_mute = "M"
        
        self.save_settings_to_file()

    def save_settings_to_file(self):
        if not self._config_file:
            return
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
            "stream_enabled": self._stream_enabled,
            "stream_volume": self._stream_volume,
            "keybind_play_pause": self._keybind_play_pause,
            "keybind_reset": self._keybind_reset,
            "keybind_settings": self._keybind_settings,
            "keybind_zen_mode": self._keybind_zen_mode,
            "keybind_stream": self._keybind_stream,
            "keybind_mute": self._keybind_mute
        }
        try:
            with open(self._config_file, 'w') as f:
                json.dump(data, f, indent=2)
        except IOError:
            pass

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
        minutes = int(math.ceil(self._seconds_remaining)) // SECONDS_IN_MINUTE
        seconds = int(math.ceil(self._seconds_remaining)) % SECONDS_IN_MINUTE
        self.timeStringChanged.emit(f"{minutes:02d}:{seconds:02d}")
        
        progress = 0.0
        if self._total_seconds_to_run > 0:
            progress = max(0.0, min(1.0, self._seconds_remaining / self._total_seconds_to_run))
        self.progressChanged.emit(progress)

    def _on_tick(self):
        if not self._is_running:
            return
        
        now = time.monotonic()
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
            self._total_seconds_to_run = self._work_minutes * SECONDS_IN_MINUTE
            
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
        self._target_end_monotonic = time.monotonic() + self._seconds_remaining
        self._timer.start()

    @Slot()
    def pause(self):
        if not self._is_running:
            return
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        self._seconds_remaining = max(0.0, self._target_end_monotonic - time.monotonic())
        self._paused_seconds_remaining = self._seconds_remaining

    @Slot()
    def reset(self):
        self._is_running = False
        self.isRunningChanged.emit(False)
        self._timer.stop()
        
        if self._current_state == "work":
            self._total_seconds_to_run = self._work_minutes * SECONDS_IN_MINUTE
        elif self._current_state == "short_break":
            self._total_seconds_to_run = self._short_break_minutes * SECONDS_IN_MINUTE
        else:
            self._total_seconds_to_run = self._long_break_minutes * SECONDS_IN_MINUTE
            
        self._seconds_remaining = float(self._total_seconds_to_run)
        self._paused_seconds_remaining = float(self._total_seconds_to_run)
        self.update_time_string()

    @Slot(int, int, int, bool, bool, bool, str, float, float, float, str, bool, bool, int, float, bool, bool, float)
    def updateSettings(self, work, short_break, long_break, aot, sound, flash, color, damping, shader_speed, meteor_freq, clock_theme, auto_breaks, auto_work, lbi, volume, ticking, stream_enabled, stream_volume):
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
        
        self.save_settings_to_file()
        
        if not self._is_running:
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
        self.save_settings_to_file()
        # Optionally, play a tiny tick sound or beep to preview volume, but for now just save.
        # Alarm volume is used by audio.py when an alarm plays.

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

    @Property(bool, notify=streamEnabledChanged)
    def streamEnabled(self): return self._stream_enabled

    @Property(float, notify=streamVolumeChanged)
    def streamVolume(self): return self._stream_volume

    @Property(str, notify=streamStatusChanged)
    def streamStatus(self): return self._stream_status

    @Property(str, notify=songTitleChanged)
    def songTitle(self): return self._song_title

    @Property(str, notify=timeStringChanged)
    def timeString(self): 
        m = int(math.ceil(self._seconds_remaining)) // SECONDS_IN_MINUTE
        s = int(math.ceil(self._seconds_remaining)) % SECONDS_IN_MINUTE
        return f"{m:02d}:{s:02d}"

    @Property(float, notify=progressChanged)
    def progress(self):
        if self._total_seconds_to_run <= 0: return 0.0
        return max(0.0, min(1.0, self._seconds_remaining / self._total_seconds_to_run))

    @Property(str, notify=currentStateChanged)
    def currentState(self): return self._current_state

    @Property(bool, notify=isRunningChanged)
    def isRunning(self): return self._is_running

    @Property(int, notify=workCountChanged)
    def workCount(self): return self._work_count

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

    def _on_stream_status_changed(self, status):
        if self._stream_status != status:
            self._stream_status = status
            self.streamStatusChanged.emit(status)

    def _on_song_title_changed(self, title):
        if self._song_title != title:
            self._song_title = title
            self.songTitleChanged.emit(title)

    @Slot()
    def toggleStream(self):
        self._streamer.toggle_mute()
        
        if not self._stream_enabled:
            self._stream_enabled = True
            self.streamEnabledChanged.emit(True)
            self.save_settings_to_file()

    @Slot(float)
    def setStreamVolume(self, volume):
        self._stream_volume = volume
        self._streamer.set_volume(volume)
        self.streamVolumeChanged.emit(volume)
        self.save_settings_to_file()
    
    def cleanup(self):
        self._streamer.stop()
