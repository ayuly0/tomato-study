import os
import sys
import tempfile
import pytest
import hashlib
from unittest.mock import patch, MagicMock
from PySide6.QtCore import QCoreApplication

# Add src/ folder to Python path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src"))

from security import (
    DataCryptor,
    HostsBlocker,
    PrivacyLockManager,
    StreamIntegrity,
    ChecksumVerifier,
    HOSTS_MARKER_START,
    HOSTS_MARKER_END,
    MAGIC_HEADER
)
from settings import SettingsManager
from timer import TimerBackend



# ============================================================================
# 1. AES-256 DataCryptor Tests
# ============================================================================

def test_datacryptor_encrypt_decrypt_roundtrip():
    secret_text = '{"work_minutes": 25, "secret_key": "tomato-ultra-safe"}'
    encrypted = DataCryptor.encrypt(secret_text)
    
    assert encrypted.startswith(MAGIC_HEADER)
    assert DataCryptor.is_encrypted(encrypted) is True
    
    decrypted = DataCryptor.decrypt(encrypted)
    assert decrypted == secret_text

def test_datacryptor_with_custom_password():
    secret_text = "Highly confidential study notes"
    pwd = "super-strong-password-123!"
    encrypted = DataCryptor.encrypt(secret_text, password=pwd)
    
    assert DataCryptor.decrypt(encrypted, password=pwd) == secret_text
    
    # Decrypting with wrong password must raise exception
    with pytest.raises(Exception):
        DataCryptor.decrypt(encrypted, password="wrong-password")

def test_datacryptor_tampered_ciphertext():
    secret_text = "Authentic message"
    encrypted = bytearray(DataCryptor.encrypt(secret_text))
    
    # Corrupt a byte in the payload
    encrypted[-1] ^= 0x55
    with pytest.raises(Exception):
        DataCryptor.decrypt(bytes(encrypted))

def test_datacryptor_non_encrypted_header():
    with pytest.raises(ValueError, match="not encrypted"):
        DataCryptor.decrypt(b"PLAINTEXT_DATA_WITHOUT_MAGIC")


# ============================================================================
# 2. Encrypted SettingsManager Tests
# ============================================================================

def test_settings_encrypted_storage_roundtrip():
    with tempfile.NamedTemporaryFile(delete=False) as tf:
        config_path = tf.name

    try:
        sm = SettingsManager(config_path)
        test_settings = sm.load()
        test_settings["work_minutes"] = 42
        test_settings["encrypt_storage"] = True
        test_settings["strict_focus_enabled"] = True
        
        # Save encrypted
        sm.save(test_settings)
        
        # Verify file content is encrypted on disk
        with open(config_path, "rb") as f:
            raw_disk_data = f.read()
        assert DataCryptor.is_encrypted(raw_disk_data) is True
        
        # Reload with SettingsManager and verify transparent decryption
        sm2 = SettingsManager(config_path)
        loaded = sm2.load()
        assert loaded["work_minutes"] == 42
        assert loaded["encrypt_storage"] is True
        assert loaded["strict_focus_enabled"] is True
    finally:
        if os.path.exists(config_path):
            os.remove(config_path)

def test_settings_plaintext_migration_to_encrypted():
    with tempfile.NamedTemporaryFile(delete=False, mode="w", encoding="utf-8") as tf:
        config_path = tf.name
        tf.write('{"work_minutes": 50, "encrypt_storage": false}')

    try:
        sm = SettingsManager(config_path)
        loaded = sm.load()
        assert loaded["work_minutes"] == 50
        
        # Switch to encrypted
        loaded["encrypt_storage"] = True
        sm.save(loaded)
        
        with open(config_path, "rb") as f:
            disk_data = f.read()
        assert DataCryptor.is_encrypted(disk_data) is True
        
        loaded_again = sm.load()
        assert loaded_again["work_minutes"] == 50
    finally:
        if os.path.exists(config_path):
            os.remove(config_path)


# ============================================================================
# 3. HostsBlocker Tests
# ============================================================================

def test_hosts_blocker_injection_and_unblock():
    initial_hosts = "127.0.0.1  localhost\n::1        localhost\n"
    
    with tempfile.NamedTemporaryFile(delete=False, mode="w", encoding="utf-8") as tf:
        hosts_path = tf.name
        tf.write(initial_hosts)

    try:
        blocker = HostsBlocker(hosts_path=hosts_path)
        assert blocker.is_blocked() is False
        
        domains = ["facebook.com", "tiktok.com"]
        success = blocker.block_domains(domains)
        assert success is True
        assert blocker.is_blocked() is True
        
        with open(hosts_path, "r", encoding="utf-8") as f:
            content = f.read()
        assert HOSTS_MARKER_START in content
        assert HOSTS_MARKER_END in content
        assert "127.0.0.1  facebook.com" in content
        assert "::1        tiktok.com" in content
        
        # Unblock
        unblock_success = blocker.unblock_all()
        assert unblock_success is True
        assert blocker.is_blocked() is False
        
        with open(hosts_path, "r", encoding="utf-8") as f:
            restored = f.read()
        assert HOSTS_MARKER_START not in restored
        assert "facebook.com" not in restored
    finally:
        if os.path.exists(hosts_path):
            os.remove(hosts_path)


# ============================================================================
# 4. ChecksumVerifier & StreamIntegrity Tests
# ============================================================================

def test_checksum_verifier_string_and_file():
    data = b"Tomato Study v0.1.0 release binary"
    expected_hash = hashlib.sha256(data).hexdigest()
    
    calc = ChecksumVerifier.calculate_sha256(data)
    assert calc == expected_hash
    
    with tempfile.NamedTemporaryFile(delete=False) as tf:
        tf.write(data)
        file_path = tf.name

    try:
        assert ChecksumVerifier.verify_file(file_path, expected_hash) is True
        assert ChecksumVerifier.verify_file(file_path, "wrong_hash") is False
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)

def test_stream_cert_fingerprint_verification():
    fake_cert_der = b"sample_certificate_der_bytes"
    fingerprint = ChecksumVerifier.calculate_sha256(fake_cert_der)
    
    assert StreamIntegrity.verify_cert_fingerprint(fake_cert_der, fingerprint) is True
    assert StreamIntegrity.verify_cert_fingerprint(fake_cert_der, "aabbccddeeff") is False


# ============================================================================
# 5. TimerBackend Strict Focus & Privacy Lock Integration
# ============================================================================

def test_timer_strict_focus_anti_exit_lock(q_app):
    backend = TimerBackend(config_file=None)
    backend.updateSettings({
        "strictFocusEnabled": True,
        "workMinutes": 25
    })
    
    # Not running yet -> can close
    assert backend.can_close() is True
    assert backend.canClose() is True
    
    # Start work session in strict focus
    with patch.object(backend._hosts_blocker, "block_domains", return_value=True) as mock_block:
        backend.start()
        assert backend.isRunning is True
        assert backend.currentState == "work"
        assert backend.strictFocusActive is True
        assert mock_block.called
        
        # During active strict focus work -> cannot close!
        assert backend.can_close() is False
        assert backend.canClose() is False
        
        # Pausing or resetting deactivates strict focus
        backend.pause()
        assert backend.strictFocusActive is False
        assert backend.can_close() is True

def test_timer_privacy_lock_triggered_on_break(q_app):
    backend = TimerBackend(config_file=None)
    backend.updateSettings({
        "privacyLockEnabled": True,
        "workMinutes": 25,
        "shortBreakMinutes": 5
    })
    
    with patch.object(backend._privacy_lock_manager, "lock_screen", return_value=True) as mock_lock:
        # Skip work session directly into break
        backend.skip()
        assert backend.currentState in ("short_break", "long_break")
        assert mock_lock.called


def test_focus_quick_view_anti_exit_protection(q_app):
    from main import FocusQuickView
    from PySide6.QtGui import QCloseEvent
    
    backend = TimerBackend(config_file=None)
    view = FocusQuickView(backend)
    
    # Session not active -> close allowed
    event1 = QCloseEvent()
    view.closeEvent(event1)
    assert event1.isAccepted() is True
    
    # Session active with strict focus -> close ignored
    backend.updateSettings({"strictFocusEnabled": True})
    with patch.object(backend._hosts_blocker, "block_domains", return_value=True):
        backend.start()
        event2 = QCloseEvent()
        view.closeEvent(event2)
        assert event2.isAccepted() is False
        
        # Pause -> close allowed again
        backend.pause()
        event3 = QCloseEvent()
        view.closeEvent(event3)
        assert event3.isAccepted() is True


def test_hosts_blocker_permission_error_handling():
    blocker = HostsBlocker(hosts_path="/nonexistent/root_only/path/hosts")
    assert blocker.block_domains(["facebook.com"]) is False
    assert blocker.unblock_all() is False


def test_qml_loads_and_initializes_cleanly(q_app):
    from PySide6.QtQuick import QQuickView
    from PySide6.QtCore import QUrl
    from constants import UI_DIR
    
    backend = TimerBackend(config_file=None)
    view = QQuickView()
    view.rootContext().setContextProperty("timerBackend", backend)
    view.setSource(QUrl.fromLocalFile(os.path.join(UI_DIR, "main.qml")))
    assert view.status() == QQuickView.Status.Ready


def test_privacy_lock_windows_platform_call():
    with patch("platform.system", return_value="Windows"), \
         patch("ctypes.windll", create=True) as mock_windll:
        mock_windll.user32.LockWorkStation.return_value = 1
        assert PrivacyLockManager.lock_screen() is True
        mock_windll.user32.LockWorkStation.assert_called_once()
