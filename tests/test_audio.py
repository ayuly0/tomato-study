import sys
import os
import unittest
from unittest.mock import MagicMock, patch
import pytest
from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtMultimedia import QMediaPlayer

# Add src/ folder to Python path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src"))

from audio import LateAudioStreamer, LocalStreamProxy

@pytest.fixture(scope="session", autouse=True)
def q_app():
    app = QCoreApplication.instance()
    if app is None:
        app = QCoreApplication(sys.argv)
    yield app

def test_streamer_stops_on_error():
    streamer = LateAudioStreamer()
    # Mock player and audio output
    streamer.player = MagicMock()
    streamer.audio_output = MagicMock()
    streamer._enabled = True
    
    # Simulate error
    streamer._on_error(QMediaPlayer.Error.ResourceError, "Demuxing failed")
    
    # Assert player.stop() was called
    streamer.player.stop.assert_called_once()
    assert streamer._status == "error"

def test_streamer_stops_on_invalid_media_status():
    streamer = LateAudioStreamer()
    streamer.player = MagicMock()
    streamer.audio_output = MagicMock()
    streamer._enabled = True
    
    # Simulate InvalidMedia status
    streamer._on_status_changed(QMediaPlayer.MediaStatus.InvalidMedia)
    
    # Assert player.stop() was called
    streamer.player.stop.assert_called_once()
    assert streamer._status == "error"

def test_playback_state_changed_preserves_error_status():
    streamer = LateAudioStreamer()
    streamer._status = "error"
    
    # Simulate state transition to StoppedState while status is error
    streamer._on_playback_state_changed(QMediaPlayer.PlaybackState.StoppedState)
    
    # Status should still be error, not idle
    assert streamer._status == "error"
