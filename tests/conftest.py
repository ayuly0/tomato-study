import os
import sys
import pytest
from PySide6.QtGui import QGuiApplication

# Ensure offscreen rendering in headless/CI test environments
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

# Add src/ folder to Python path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src"))

@pytest.fixture(scope="session", autouse=True)
def q_app():
    app = QGuiApplication.instance()
    if app is None:
        app = QGuiApplication(sys.argv)
    import qtawesome as qta
    qta.font("fa6s", 16)
    yield app
