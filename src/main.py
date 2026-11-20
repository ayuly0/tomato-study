import sys
import os
import shutil
import subprocess

# Force OpenGL graphics rendering backend in Qt Quick RHI
os.environ["QSG_RHI_BACKEND"] = "opengl"

# Add current directory to path for local module imports
SRC_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SRC_DIR)

from PySide6.QtCore import QUrl, QEvent
from PySide6.QtGui import QGuiApplication, QCloseEvent
from PySide6.QtQuick import QQuickView
from timer import TimerBackend, UI_DIR

class FocusQuickView(QQuickView):
    """Custom QQuickView supporting anti-exit protection during Strict Focus."""
    def __init__(self, backend, parent=None):
        super().__init__(parent)
        self._backend = backend

    def closeEvent(self, event: QCloseEvent):
        if self._backend and not self._backend.can_close():
            event.ignore()
            return
        super().closeEvent(event)

def compile_shader():
    """Compiles the GLSL fragment shader to QSB package if qsb compiler is available."""
    qsb_source = os.path.join(UI_DIR, "shader.frag")
    qsb_output = os.path.join(UI_DIR, "shader.frag.qsb")
    
    if not os.path.exists(qsb_source):
        return

    # Check if pre-compiled qsb exists and is newer than source
    if os.path.exists(qsb_output):
        try:
            if os.path.getmtime(qsb_output) >= os.path.getmtime(qsb_source):
                return
        except OSError:
            pass

    # Search for QSB compiler cross-platform
    candidate_names = ["qsb", "pyside6-qsb", "qsb.exe", "pyside6-qsb.exe"]
    qsb_bin = None
    for name in candidate_names:
        found = shutil.which(name)
        if found:
            qsb_bin = found
            break

    if not qsb_bin:
        fallback_candidates = [
            "/usr/lib/qt6/bin/qsb",
            os.path.join(sys.prefix, "bin", "pyside6-qsb"),
            os.path.join(sys.prefix, "Scripts", "pyside6-qsb.exe"),
        ]
        for path in fallback_candidates:
            if os.path.exists(path):
                qsb_bin = path
                break

    if not qsb_bin:
        return

    try:
        subprocess.run([qsb_bin, "--qt6", "-o", qsb_output, qsb_source], check=True, capture_output=True)
    except Exception:
        pass

def main():
    compile_shader()
    
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Tomato Study")
    app.setOrganizationName("TomatoStudy")
    
    # Pre-load QtAwesome Font Awesome 6 font family into QFontDatabase
    import qtawesome as qta
    qta.font("fa6s", 16)
    
    backend = TimerBackend()
    
    # Register clean shutdown slot
    app.aboutToQuit.connect(backend.cleanup)
    
    view = FocusQuickView(backend)
    view.setTitle("Tomato Study")
    
    # Associate backend to adjust stays-on-top flags
    backend.set_view(view)
    
    # Register backend into QML Context
    view.rootContext().setContextProperty("timerBackend", backend)
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    
    qml_file = os.path.join(UI_DIR, "main.qml")
    view.setSource(QUrl.fromLocalFile(qml_file))
    
    view.setWidth(350)
    view.setHeight(400)
    view.show()
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
