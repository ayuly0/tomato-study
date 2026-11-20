import os

# Configuration Defaults
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
DEFAULT_COMPACT_WIDTH_THRESHOLD = 400
DEFAULT_COMPACT_HEIGHT_THRESHOLD = 250
DEFAULT_CLOCK_SCALE = 1.0

# Digital Wellbeing & Security Defaults
DEFAULT_STRICT_FOCUS_ENABLED = False
DEFAULT_PRIVACY_LOCK_ENABLED = False
DEFAULT_ENCRYPT_STORAGE = False
DEFAULT_BLOCKED_DOMAINS = [
    "facebook.com",
    "www.facebook.com",
    "youtube.com",
    "www.youtube.com",
    "tiktok.com",
    "www.tiktok.com",
    "instagram.com",
    "www.instagram.com",
    "x.com",
    "twitter.com",
    "reddit.com",
    "www.reddit.com"
]

# OS Hosts file locations
import platform
if platform.system() == "Windows":
    DEFAULT_HOSTS_PATH = os.path.join(os.environ.get("SystemRoot", "C:\\Windows"), "System32", "drivers", "etc", "hosts")
else:
    DEFAULT_HOSTS_PATH = "/etc/hosts"

# Timer Tick Frequency
TIMER_TICK_INTERVAL_MS = 100
SECONDS_IN_MINUTE = 60

# Directory and File Paths
SRC_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SRC_DIR)
UI_DIR = os.path.join(PROJECT_DIR, "ui")
CONFIG_FILE_NAME = os.path.join(PROJECT_DIR, "config.json")
CHIME_FILE_NAME = os.path.join(UI_DIR, "chime.wav")
TICK_FILE_NAME = os.path.join(UI_DIR, "tick.wav")
