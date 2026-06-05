import math
from PySide6.QtCore import QObject, Signal, Property, Slot, QUrl, Qt
from PySide6.QtMultimedia import QSoundEffect
from audio import generate_chime_wav, generate_tick_wav
from constants import CHIME_FILE_NAME, TICK_FILE_NAME

class TimerProperties(QObject):
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
    activePresetChanged = Signal(str)
    timerModeChanged = Signal(str)
    presetsListChanged = Signal(list)

    def setup_sound(self):
        generate_chime_wav(CHIME_FILE_NAME)
        self._sound_effect = QSoundEffect(self)
        self._sound_effect.setSource(QUrl.fromLocalFile(CHIME_FILE_NAME))
        self._sound_effect.setVolume(self._alarm_volume)
        
        generate_tick_wav(TICK_FILE_NAME)
        self._tick_effect = QSoundEffect(self)
        self._tick_effect.setSource(QUrl.fromLocalFile(TICK_FILE_NAME))
        self._tick_effect.setVolume(self._alarm_volume * 0.4)

    def apply_always_on_top(self, enabled):
        if not self._view:
            return
        flags = self._view.flags()
        if enabled:
            self._view.setFlags(flags | Qt.WindowStaysOnTopHint)
        else:
            self._view.setFlags(flags & ~Qt.WindowStaysOnTopHint)
        self._view.show()

    # Keybinds and Audio Volume Slots
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

    @Slot()
    def toggleStream(self):
        self._streamer.toggle_mute()
        
        if not self._stream_enabled:
            self._stream_enabled = True
            self.streamEnabledChanged.emit(True)
            self.save_settings_to_file()
            
        self.streamMutedChanged.emit(self.streamMuted)

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
