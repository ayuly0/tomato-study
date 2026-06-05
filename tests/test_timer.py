import sys
import os
import pytest
from PySide6.QtCore import QCoreApplication

# Add src/ folder to Python path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src"))

from timer import TimerBackend, DEFAULT_WORK_MINUTES

# Fixture to provide a single QCoreApplication instance required for QObject creation
@pytest.fixture(scope="session", autouse=True)
def q_app():
    app = QCoreApplication.instance()
    if app is None:
        app = QCoreApplication(sys.argv)
    yield app

def test_initial_state():
    backend = TimerBackend(config_file=None)
    assert backend.workMinutes == DEFAULT_WORK_MINUTES
    assert backend.currentState == "work"
    assert backend.isRunning is False
    assert backend.progress == 1.0
    assert backend.timeString == f"{DEFAULT_WORK_MINUTES:02d}:00"
    assert backend.streamEnabled is False
    assert backend.streamVolume == 0.5

def test_settings_updates():
    backend = TimerBackend(config_file=None)
    backend.updateSettings(
        work=15,
        short_break=3,
        long_break=8,
        aot=False,
        sound=False,
        flash=False,
        color="#ffffff",
        damping=0.08,
        shader_speed=0.02,
        meteor_freq=0.6,
        auto_breaks=True,
        auto_work=True,
        lbi=3,
        volume=0.5,
        ticking=True,
        stream_enabled=True,
        stream_volume=0.8
    )
    assert backend.workMinutes == 15
    assert backend.shortBreakMinutes == 3
    assert backend.longBreakMinutes == 8
    assert backend.alwaysOnTop is False
    assert backend.soundEnabled is False
    assert backend.flashEnabled is False
    assert backend.themeColor == "#ffffff"
    assert backend.shaderDamping == 0.08
    assert backend.shaderSpeed == 0.02
    assert backend.meteorFrequency == 0.6
    assert backend.autoStartBreaks is True
    assert backend.autoStartWork is True
    assert backend.longBreakInterval == 3
    assert backend.alarmVolume == 0.5
    assert backend.tickingEnabled is True
    assert backend.streamEnabled is True
    assert backend.streamVolume == 0.8
    assert backend.timeString == "15:00"

def test_timer_transitions():
    backend = TimerBackend(config_file=None)
    backend.updateSettings(
        work=10,
        short_break=2,
        long_break=5,
        aot=False,
        sound=False,
        flash=False,
        color="#ffffff",
        damping=0.05,
        shader_speed=0.015,
        meteor_freq=0.4,
        auto_breaks=False,
        auto_work=False,
        lbi=4,
        volume=1.0,
        ticking=False,
        stream_enabled=False,
        stream_volume=0.5
    )
    backend.start()
    assert backend.isRunning is True
    
    # 1st Work session finish -> Transition to Short Break
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "short_break"
    assert backend.isRunning is False
    assert backend.timeString == "02:00"
    
    # Short Break finish -> Transition to Work
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "work"
    assert backend.isRunning is False
    assert backend.timeString == "10:00"
    
    # 2nd Work session finish -> Transition to Short Break
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "short_break"
    
    # Short Break finish -> Transition to Work
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "work"
    
    # 3rd Work session finish -> Transition to Short Break
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "short_break"
    
    # Short Break finish -> Transition to Work
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "work"
    
    # 4th Work session finish -> Transition to Long Break (15-min cycles)
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "long_break"
    assert backend.timeString == "05:00"

def test_long_break_interval():
    backend = TimerBackend(config_file=None)
    backend.updateSettings(
        work=10,
        short_break=2,
        long_break=5,
        aot=False,
        sound=False,
        flash=False,
        color="#ffffff",
        damping=0.05,
        shader_speed=0.015,
        meteor_freq=0.4,
        auto_breaks=False,
        auto_work=False,
        lbi=2,
        volume=1.0,
        ticking=False,
        stream_enabled=False,
        stream_volume=0.5
    )
    backend.start()
    
    # 1st Work session finish -> Transition to Short Break
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "short_break"
    
    # Short Break finish -> Transition to Work
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "work"
    
    # 2nd Work session finish -> Transition to Long Break (triggered at 2 intervals)
    backend.start()
    backend._target_end_monotonic = 0.0
    backend._on_tick()
    assert backend.currentState == "long_break"
    assert backend.timeString == "05:00"
