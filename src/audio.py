import os
import socket
import threading
import urllib.request
import wave
import struct
import math
from PySide6.QtCore import QObject, QUrl
from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput

# Named constants to avoid magic numbers
CHIME_SAMPLE_RATE = 44100.0
CHIME_DURATION_SEC = 1.2
PRIMARY_FREQ = 587.33  # D5 note
HARMONIC_FREQ = 880.00  # A5 note
TICK_SAMPLE_RATE = 44100
TICK_DURATION_SEC = 0.025
TICK_FREQ = 1400.0
BUFFER_SIZE = 4096
TIMEOUT_SEC = 5

class LocalStreamProxy:
    """A local TCP HTTP proxy server that forwards streaming audio from an HTTPS source

    to a plain HTTP port, bypassing OS-specific TLS handshake issues in GStreamer/FFmpeg.
    """
    def __init__(self, target_url):
        self.target_url = target_url
        self.server_socket = None
        self.port = 0
        self.thread = None
        self.running = False
        
    def start(self) -> str:
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.bind(('127.0.0.1', 0))
        self.port = self.server_socket.getsockname()[1]
        self.server_socket.listen(1)
        self.running = True
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()
        return f"http://127.0.0.1:{self.port}/stream"
        
    def stop(self):
        self.running = False
        if self.server_socket:
            try:
                # Wake up the accept() block by connecting to it
                dummy = socket.socket()
                dummy.settimeout(0.1)
                dummy.connect(('127.0.0.1', self.port))
                dummy.close()
            except Exception:
                pass
            try:
                self.server_socket.close()
            except Exception:
                pass

    def _run(self):
        while self.running:
            try:
                client_sock, addr = self.server_socket.accept()
            except Exception:
                break
            if not self.running:
                client_sock.close()
                break
            # Handle each connection in a separate thread
            threading.Thread(target=self._handle_client, args=(client_sock,), daemon=True).start()

    def _handle_client(self, client_sock):
        try:
            req_data = b""
            while b"\r\n\r\n" not in req_data:
                chunk = client_sock.recv(1024)
                if not chunk:
                    break
                req_data += chunk
                
            client_sock.sendall(
                b"HTTP/1.1 200 OK\r\n"
                b"Content-Type: audio/mpeg\r\n"
                b"Connection: close\r\n"
                b"Cache-Control: no-cache\r\n\r\n"
            )
            
            req = urllib.request.Request(self.target_url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=TIMEOUT_SEC) as response:
                while self.running:
                    data = response.read(BUFFER_SIZE)
                    if not data:
                        break
                    client_sock.sendall(data)
        except Exception:
            pass
        finally:
            try:
                client_sock.close()
            except Exception:
                pass


class LateAudioStreamer(QObject):
    """Manages the lifecycle, playback state, and volume of the late.sh background music stream."""
    def __init__(self, target_url="https://audio.late.sh/stream", parent=None):
        super().__init__(parent)
        self.target_url = target_url
        self.proxy = None
        self.player = None
        self.audio_output = None
        self._volume = 0.5
        self._enabled = False
        
    def set_enabled(self, enabled: bool):
        if self._enabled == enabled:
            return
        self._enabled = enabled
        
        if enabled:
            self.proxy = LocalStreamProxy(self.target_url)
            local_url = self.proxy.start()
            
            self.player = QMediaPlayer()
            self.audio_output = QAudioOutput()
            self.player.setAudioOutput(self.audio_output)
            self.audio_output.setVolume(self._volume)
            
            self.player.setSource(QUrl(local_url))
            self.player.play()
        else:
            self.stop()
            
    def set_volume(self, volume: float):
        self._volume = max(0.0, min(1.0, volume))
        if self.audio_output:
            self.audio_output.setVolume(self._volume)
            
    def stop(self):
        if self.player:
            self.player.stop()
            self.player = None
        if self.audio_output:
            self.audio_output = None
        if self.proxy:
            self.proxy.stop()
            self.proxy = None
        self._enabled = False


def generate_chime_wav(filename: str):
    """Generates a pleasant harmonic sine wave chime with exponential decay to a WAV file."""
    if os.path.exists(filename):
        return
    
    wave_file = wave.open(filename, 'w')
    wave_file.setparams((1, 2, int(CHIME_SAMPLE_RATE), 0, 'NONE', 'not compressed'))
    
    total_samples = int(CHIME_DURATION_SEC * CHIME_SAMPLE_RATE)
    for x in range(total_samples):
        time_t = x / CHIME_SAMPLE_RATE
        decay = math.exp(-3.0 * time_t)  # Exponential decay for bell-like tone
        
        # Mix two frequencies (D5 and A5) for a harmonious chime
        val = 0.6 * math.sin(2 * math.pi * PRIMARY_FREQ * time_t) + \
              0.4 * math.sin(2 * math.pi * HARMONIC_FREQ * time_t)
        
        value = int(val * decay * 32767)
        data = struct.pack('<h', value)
        wave_file.writeframesraw(data)
        
    wave_file.close()


def generate_tick_wav(filename: str):
    """Generates a pleasant, extremely short and soft ticking sound to a WAV file."""
    if os.path.exists(filename):
        return
    
    wave_file = wave.open(filename, 'w')
    wave_file.setparams((1, 2, TICK_SAMPLE_RATE, 0, 'NONE', 'not compressed'))
    
    total_samples = int(TICK_DURATION_SEC * TICK_SAMPLE_RATE)
    for x in range(total_samples):
        time_t = x / float(TICK_SAMPLE_RATE)
        decay = math.exp(-220.0 * time_t)  # Extremely fast exponential decay
        val = 0.05 * math.sin(2 * math.pi * TICK_FREQ * time_t)  # Soft high-pitched click
        value = int(val * decay * 32767)
        data = struct.pack('<h', value)
        wave_file.writeframesraw(data)
        
    wave_file.close()
