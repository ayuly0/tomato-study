import os
import sys
import re
import ssl
import hashlib
import platform
import subprocess
import shutil
from typing import List, Optional

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

from constants import DEFAULT_HOSTS_PATH, DEFAULT_BLOCKED_DOMAINS


# ============================================================================
# 1. Strict Focus: Hosts Blocker (Anti-Bypass / Endpoint Control)
# ============================================================================

HOSTS_MARKER_START = "# --- START TOMATO STUDY STRICT FOCUS ---"
HOSTS_MARKER_END = "# --- END TOMATO STUDY STRICT FOCUS ---"

class HostsBlocker:
    """Manages blocking distracting websites via OS hosts file manipulation."""
    
    def __init__(self, hosts_path: str = DEFAULT_HOSTS_PATH):
        self.hosts_path = hosts_path
        
    def is_blocked(self) -> bool:
        """Returns True only when a complete managed block exists."""
        if not os.path.exists(self.hosts_path):
            return False
        try:
            with open(self.hosts_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            return re.search(
                rf"{re.escape(HOSTS_MARKER_START)}.*?{re.escape(HOSTS_MARKER_END)}",
                content,
                re.DOTALL,
            ) is not None
        except (OSError, UnicodeError):
            return False

    def block_domains(self, domains: Optional[List[str]] = None) -> bool:
        """Adds localhost redirects for target domains inside the hosts file."""
        if domains is None:
            domains = DEFAULT_BLOCKED_DOMAINS
        if not os.path.exists(self.hosts_path):
            return False
        try:
            with open(self.hosts_path, "r", encoding="utf-8", errors="ignore") as hosts_file:
                content = hosts_file.read()
            pattern = re.compile(
                rf"{re.escape(HOSTS_MARKER_START)}.*?{re.escape(HOSTS_MARKER_END)}\n?",
                re.DOTALL,
            )
            clean_content = pattern.sub("", content).rstrip() + "\n"
            block_lines = [HOSTS_MARKER_START, "# Automated distraction blocker during active Pomodoro session"]
            for domain in domains:
                clean_domain = domain.strip().lower()
                if clean_domain:
                    block_lines.extend((f"127.0.0.1  {clean_domain}", f"::1        {clean_domain}"))
            block_lines.extend((HOSTS_MARKER_END, ""))
            new_content = clean_content + "\n".join(block_lines)
            temp_path = f"{self.hosts_path}.tomato.tmp"
            with open(temp_path, "w", encoding="utf-8") as temp_file:
                temp_file.write(new_content)
                temp_file.flush()
                os.fsync(temp_file.fileno())
            shutil.move(temp_path, self.hosts_path)
            return self.is_blocked()
        except (PermissionError, OSError):
            return False

    def unblock_all(self) -> bool:
        """Removes all Tomato Study blocks from the hosts file."""
        if not os.path.exists(self.hosts_path):
            return False
        try:
            with open(self.hosts_path, "r", encoding="utf-8", errors="ignore") as hosts_file:
                content = hosts_file.read()
            pattern = re.compile(
                rf"\n?{re.escape(HOSTS_MARKER_START)}.*?{re.escape(HOSTS_MARKER_END)}\n?",
                re.DOTALL,
            )
            new_content = pattern.sub("\n", content).rstrip() + "\n"
            temp_path = f"{self.hosts_path}.tomato.tmp"
            with open(temp_path, "w", encoding="utf-8") as temp_file:
                temp_file.write(new_content)
                temp_file.flush()
                os.fsync(temp_file.fileno())
            shutil.move(temp_path, self.hosts_path)
            return not self.is_blocked()
        except (PermissionError, OSError):
            return False



# ============================================================================
# 2. Privacy Screen Lock
# ============================================================================

class PrivacyLockManager:
    """Invokes system screen lock across Windows, macOS, and Linux."""
    
    @staticmethod
    def lock_screen() -> bool:
        current_os = platform.system()
        try:
            if current_os == "Windows":
                import ctypes
                return bool(ctypes.windll.user32.LockWorkStation())
            elif current_os == "Darwin":
                # macOS
                cg_session = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
                if os.path.exists(cg_session):
                    res = subprocess.run([cg_session, "-suspend"], capture_output=True)
                    if res.returncode == 0:
                        return True
                res = subprocess.run(["pmset", "displaysleepnow"], capture_output=True)
                return res.returncode == 0
            elif current_os == "Linux":
                candidates = [
                    ["loginctl", "lock-session"],
                    ["xdg-screensaver", "lock"],
                    ["gnome-screensaver-command", "-l"],
                    ["qdbus", "org.freedesktop.ScreenSaver", "/ScreenSaver", "Lock"]
                ]
                for cmd in candidates:
                    if shutil.which(cmd[0]):
                        res = subprocess.run(cmd, capture_output=True)
                        if res.returncode == 0:
                            return True
                return False
        except Exception:
            return False
        return False


# ============================================================================
# 3. Local Data Encryption: AES-256 (AES-GCM)
# ============================================================================

MAGIC_HEADER = b"TOMATO_AES256_GCM:"

class DataCryptor:
    """Encrypts and decrypts local application configurations using AES-256-GCM."""
    
    @staticmethod
    def _get_machine_id() -> str:
        """Derives a device-specific key seed to avoid storing keys in plaintext."""
        try:
            if platform.system() == "Linux":
                for path in ["/etc/machine-id", "/var/lib/dbus/machine-id"]:
                    if os.path.exists(path):
                        with open(path, "r") as f:
                            return f.read().strip()
            elif platform.system() == "Windows":
                import winreg
                registry_key = winreg.OpenKey(
                    winreg.HKEY_LOCAL_MACHINE, 
                    r"SOFTWARE\Microsoft\Cryptography", 
                    0, 
                    winreg.KEY_READ | winreg.KEY_WOW64_64KEY
                )
                machine_guid, _ = winreg.QueryValueEx(registry_key, "MachineGuid")
                winreg.CloseKey(registry_key)
                return machine_guid
            elif platform.system() == "Darwin":
                output = subprocess.check_output(["ioreg", "-rd1", "-c", "IOPlatformExpertDevice"]).decode()
                match = re.search(r'"IOPlatformUUID"\s*=\s*"([^"]+)"', output)
                if match:
                    return match.group(1)
        except Exception:
            pass
        return f"{platform.node()}-{os.getlogin() if hasattr(os, 'getlogin') else 'tomato'}"

    @classmethod
    def derive_key(cls, password: Optional[str] = None, salt: Optional[bytes] = None) -> tuple[bytes, bytes]:
        """Derives a 256-bit (32 bytes) AES key using PBKDF2HMAC."""
        if salt is None:
            salt = os.urandom(16)
        secret = (password or cls._get_machine_id()).encode("utf-8")
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,  # 256 bits for AES-256
            salt=salt,
            iterations=100_000,
        )
        key = kdf.derive(secret)
        return key, salt

    @classmethod
    def encrypt(cls, plaintext: str, password: Optional[str] = None) -> bytes:
        """Encrypts plaintext with AES-256-GCM. Returns header + salt + nonce + ciphertext."""
        salt = os.urandom(16)
        key, _ = cls.derive_key(password=password, salt=salt)
        aesgcm = AESGCM(key)
        nonce = os.urandom(12)  # 96-bit nonce standard for GCM
        ciphertext = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), None)
        return MAGIC_HEADER + salt + nonce + ciphertext

    @classmethod
    def decrypt(cls, data: bytes, password: Optional[str] = None) -> str:
        """Decrypts AES-256-GCM encrypted data. Throws ValueError if corrupted or wrong key."""
        if not data.startswith(MAGIC_HEADER):
            raise ValueError("Data is not encrypted with Tomato Study AES-256")
        
        payload = data[len(MAGIC_HEADER):]
        if len(payload) < 28:  # 16 salt + 12 nonce
            raise ValueError("Ciphertext payload is truncated")
            
        salt = payload[:16]
        nonce = payload[16:28]
        ciphertext = payload[28:]
        
        key, _ = cls.derive_key(password=password, salt=salt)
        aesgcm = AESGCM(key)
        decrypted_bytes = aesgcm.decrypt(nonce, ciphertext, None)
        return decrypted_bytes.decode("utf-8")

    @classmethod
    def is_encrypted(cls, data: bytes) -> bool:
        return data.startswith(MAGIC_HEADER)


# ============================================================================
# 4. Stream & Update Integrity (SSL/TLS Pinning & Checksum Verification)
# ============================================================================

class StreamIntegrity:
    """Strict SSL/TLS verification and optional Certificate Pinning for audio stream."""
    
    @staticmethod
    def create_ssl_context(expected_fingerprint: Optional[str] = None) -> ssl.SSLContext:
        """Creates a hardened SSLContext with TLS 1.2+ minimum and strict certificate validation."""
        context = ssl.create_default_context()
        context.minimum_version = ssl.TLSVersion.TLSv1_2
        context.check_hostname = True
        context.verify_mode = ssl.CERT_REQUIRED
        return context

    @staticmethod
    def verify_cert_fingerprint(cert_der: bytes, expected_fingerprint: str) -> bool:
        """Compares SHA-256 fingerprint against DER-encoded X509 certificate."""
        actual_sha256 = hashlib.sha256(cert_der).hexdigest().lower()
        clean_expected = expected_fingerprint.replace(":", "").lower().strip()
        return actual_sha256 == clean_expected


class ChecksumVerifier:
    """Calculates and verifies SHA-256 checksums for application updates and assets."""
    
    @staticmethod
    def calculate_sha256(filepath_or_bytes: str | bytes) -> str:
        sha = hashlib.sha256()
        if isinstance(filepath_or_bytes, (bytes, bytearray)):
            sha.update(filepath_or_bytes)
        else:
            with open(filepath_or_bytes, "rb") as f:
                for chunk in iter(lambda: f.read(65536), b""):
                    sha.update(chunk)
        return sha.hexdigest().lower()

    @classmethod
    def verify_file(cls, filepath: str, expected_sha256: str) -> bool:
        if not os.path.exists(filepath):
            return False
        return cls.calculate_sha256(filepath) == expected_sha256.lower().strip()
