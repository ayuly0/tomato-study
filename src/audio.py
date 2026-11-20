import os
import socket
import threading
import urllib.request
import ssl
import wave
import struct
import math
import re
from PySide6.QtCore import QObject, QUrl, Signal
from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput

from security import StreamIntegrity

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
RECONNECT_DELAY_SEC = 2.0
RETRY_DELAY_SEC = 1.0

class LocalStreamProxy:
    """A local TCP HTTP proxy server that forwards streaming audio from an HTTPS source
    to a plain HTTP port, parsing and stripping embedded ICY metadata.
    Enforces strict TLS verification and optional certificate pinning.
    """
    def __init__(self, target_url, metadata_callback=None, expected_fingerprint=None, ssl_context=None):
        self.target_url = target_url
        self.metadata_callback = metadata_callback
        self.expected_fingerprint = expected_fingerprint
        self.ssl_context = ssl_context or StreamIntegrity.create_ssl_context(expected_fingerprint)
        self.server_socket = None
        self.port = 0
        self.thread = None
        self.running = False
        self.active_sockets = set()
        self.sockets_lock = threading.Lock()
        
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
        with self.sockets_lock:
            for s in list(self.active_sockets):
                try:
                    s.shutdown(socket.SHUT_RDWR)
                except Exception:
                    pass
                try:
                    s.close()
                except Exception:
                    pass
            self.active_sockets.clear()
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
        with self.sockets_lock:
            if not self.running:
                client_sock.close()
                return
            self.active_sockets.add(client_sock)
        try:
            req_data = b""
            while b"\r\n\r\n" not in req_data:
                chunk = client_sock.recv(1024)
                if not chunk:
                    break
                req_data += chunk
                
            if not self.running or b"\r\n\r\n" not in req_data:
                return

            try:
                client_sock.sendall(
                    b"HTTP/1.1 200 OK\r\n"
                    b"Content-Type: audio/mpeg\r\n"
                    b"Connection: close\r\n"
                    b"Cache-Control: no-cache\r\n\r\n"
                )
            except (BrokenPipeError, ConnectionResetError, OSError):
                return
            
            import time
            while self.running:
                try:
                    req = urllib.request.Request(
                        self.target_url, 
                        headers={
                            "User-Agent": "Mozilla/5.0",
                            "Icy-MetaData": "1"
                        }
                    )
                    try:
                        if not (self.target_url.startswith("https://") or self.target_url.startswith("http://")):
                            raise ValueError(f"Unsupported stream protocol: {self.target_url}")
                        open_kwargs = {"timeout": TIMEOUT_SEC}
                        if self.target_url.startswith("https://") and self.ssl_context:
                            open_kwargs["context"] = self.ssl_context
                        response = urllib.request.urlopen(req, **open_kwargs)  # nosec B310
                        
                        # Validate certificate fingerprint if pinning is configured
                        if self.expected_fingerprint and hasattr(response, "fp") and hasattr(response.fp, "raw"):
                            sock = getattr(response.fp.raw, "_sock", None)
                            if sock and hasattr(sock, "getpeercert"):
                                cert_der = sock.getpeercert(binary_form=True)
                                if cert_der and not StreamIntegrity.verify_cert_fingerprint(cert_der, self.expected_fingerprint):
                                    response.close()
                                    raise ssl.SSLCertVerificationError("Pinned certificate fingerprint mismatch")
                    except Exception:
                        # Sleep before retrying remote connection
                        time.sleep(RECONNECT_DELAY_SEC)
                        continue
                        
                    with response:
                        headers = {k.lower(): v for k, v in response.getheaders()}
                        metaint = int(headers.get("icy-metaint", 0))
                        
                        if metaint > 0:
                            while self.running:
                                bytes_to_read = metaint
                                while bytes_to_read > 0 and self.running:
                                    chunk_size = min(bytes_to_read, BUFFER_SIZE)
                                    try:
                                        data = response.read(chunk_size)
                                    except Exception:
                                        data = None
                                        
                                    if not data:
                                        break  # Trigger remote reconnect
                                        
                                    try:
                                        client_sock.sendall(data)
                                    except Exception:
                                        return  # Client disconnected, exit
                                    bytes_to_read -= len(data)
                                    
                                if not self.running or not data:
                                    break
                                    
                                try:
                                    len_byte = response.read(1)
                                except Exception:
                                    break
                                    
                                if not len_byte:
                                    break
                                    
                                metadata_len = len_byte[0] * 16
                                if metadata_len > 0:
                                    try:
                                        meta_data = response.read(metadata_len)
                                    except Exception:
                                        break
                                    if len(meta_data) < metadata_len:
                                        break
                                        
                                    if self.metadata_callback:
                                        meta_str = meta_data.decode('utf-8', errors='ignore')
                                        match = re.search(r"StreamTitle='([^']*)'", meta_str)
                                        if match:
                                            self.metadata_callback(match.group(1))
                        else:
                            while self.running:
                                try:
                                    data = response.read(BUFFER_SIZE)
                                except Exception:
                                    break
                                if not data:
                                    break
                                try:
                                    client_sock.sendall(data)
                                except Exception:
                                    return  # Client disconnected, exit
                    if self.running:
                        time.sleep(RETRY_DELAY_SEC)
                except Exception:
                    if self.running:
                        time.sleep(RETRY_DELAY_SEC)
                    else:
                        break
        except Exception:
            pass
        finally:
            with self.sockets_lock:
                self.active_sockets.discard(client_sock)
                try:
                    client_sock.close()
                except Exception:
                    pass


class LateAudioStreamer(QObject):
    """Manages the lifecycle, playback state, and volume of the late.sh background music stream."""
    statusChanged = Signal(str)
    songTitleChanged = Signal(str)

    def __init__(self, target_url="https://audio.late.sh/stream", parent=None):
        super().__init__(parent)
        self.target_url = target_url
        self.proxy = None
        self.player = None
        self.audio_output = None
        self._volume = 0.5
        self._enabled = False
        self._is_muted = False
        self._status = "idle"
        self.song_title = ""
        self._reconnect_timer = None
        
    def set_enabled(self, enabled: bool):
        if self._enabled == enabled:
            return
        self._enabled = enabled
        
        if enabled:
            if self._reconnect_timer is not None:
                self._reconnect_timer.stop()
                self._reconnect_timer = None
                
            self.proxy = LocalStreamProxy(self.target_url, self._on_metadata_received)
            local_url = self.proxy.start()
            
            self.player = QMediaPlayer()
            self.audio_output = QAudioOutput()
            self.player.setAudioOutput(self.audio_output)
            self.audio_output.setVolume(self._volume)
            
            self.player.mediaStatusChanged.connect(self._on_status_changed)
            self.player.playbackStateChanged.connect(self._on_playback_state_changed)
            self.player.errorOccurred.connect(self._on_error)
            
            self.player.setSource(QUrl(local_url))
            self.player.play()
            self._update_status("buffering")
        else:
            self.stop()
            
    def toggle_mute(self):
        if not self._enabled:
            # If not enabled, enable it.
            self.set_enabled(True)
            self._is_muted = False
        else:
            self._is_muted = not self._is_muted
            if self.audio_output:
                self.audio_output.setVolume(0.0 if self._is_muted else self._volume)
            
            if self._is_muted:
                self._update_status("paused")
            else:
                state = self.player.playbackState() if self.player else None
                if state == QMediaPlayer.PlaybackState.PlayingState:
                    self._update_status("playing")
                else:
                    self._update_status("buffering")
            
    def set_volume(self, volume: float):
        self._volume = max(0.0, min(1.0, volume))
        if self.audio_output and not self._is_muted:
            self.audio_output.setVolume(self._volume)
            
    def stop(self):
        if self._reconnect_timer is not None:
            self._reconnect_timer.stop()
            self._reconnect_timer = None
        if self.player:
            self.player.stop()
            self.player = None
        if self.audio_output:
            self.audio_output = None
        if self.proxy:
            self.proxy.stop()
            self.proxy = None
        self._enabled = False
        self._update_status("idle")
        self._on_metadata_received("")

    def _on_metadata_received(self, song_title):
        # Strip trailing "| <numbers>" if present (common in lo-fi stream names)
        title = re.sub(r'\s*\|\s*\d+\s*$', '', song_title).strip()
        if self.song_title != title:
            self.song_title = title
            self.songTitleChanged.emit(title)

    def _on_status_changed(self, status):
        if self._is_muted:
            self._update_status("paused")
            return

        if status == QMediaPlayer.MediaStatus.LoadingMedia:
            self._update_status("buffering")
        elif status in (QMediaPlayer.MediaStatus.LoadedMedia, QMediaPlayer.MediaStatus.BufferedMedia):
            state = self.player.playbackState() if self.player else None
            if state == QMediaPlayer.PlaybackState.PlayingState:
                self._update_status("playing")
            else:
                self._update_status("loaded")
        elif status == QMediaPlayer.MediaStatus.StalledMedia:
            self._update_status("buffering")
        elif status == QMediaPlayer.MediaStatus.InvalidMedia:
            self._update_status("error")
            if self.player:
                self.player.stop()
            self._handle_offline_reconnect()

    def _on_playback_state_changed(self, state):
        if self._is_muted:
            self._update_status("paused")
            return

        if self._status == "error":
            return

        if state == QMediaPlayer.PlaybackState.PlayingState:
            self._update_status("playing")
        elif state == QMediaPlayer.PlaybackState.PausedState:
            self._update_status("paused")
        elif state == QMediaPlayer.PlaybackState.StoppedState:
            self._update_status("idle")

    def _on_error(self, error=None, error_string=""):
        if error is None and self.player:
            error = self.player.error()
            error_string = self.player.errorString()
        print(f"LateAudioStreamer Player Error: {error} - {error_string}")
        self._update_status("error")
        if self.player:
            self.player.stop()
        self._handle_offline_reconnect()

    def _handle_offline_reconnect(self):
        if self._enabled:
            # Reconnect automatically after 5 seconds if we went offline
            from PySide6.QtCore import QTimer
            if self._reconnect_timer is not None:
                self._reconnect_timer.stop()
            self._reconnect_timer = QTimer(self)
            self._reconnect_timer.setSingleShot(True)
            self._reconnect_timer.setInterval(5000)
            self._reconnect_timer.timeout.connect(self._reconnect)
            self._reconnect_timer.start()

    def _reconnect(self):
        self._reconnect_timer = None
        if self._enabled:
            print("LateAudioStreamer: Reconnecting...")
            was_muted = self._is_muted
            self.stop()
            self.set_enabled(True)
            self._is_muted = was_muted
            if self.audio_output:
                self.audio_output.setVolume(0.0 if self._is_muted else self._volume)
            if self._is_muted:
                self._update_status("paused")

    def _update_status(self, new_status):
        if self._status != new_status:
            self._status = new_status
            self.statusChanged.emit(new_status)


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
