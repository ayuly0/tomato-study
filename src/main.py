import sys
import os

# Force OpenGL graphics rendering backend in Qt Quick RHI
os.environ["QSG_RHI_BACKEND"] = "opengl"

# Add current directory to path for local module imports
SRC_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SRC_DIR)

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from timer import TimerBackend, UI_DIR

def compile_shader():
    """Compiles the GLSL fragment shader to QSB package at startup if qsb is available."""
    qsb_source = os.path.join(UI_DIR, "shader.frag")
    qsb_output = os.path.join(UI_DIR, "shader.frag.qsb")
    
    if not os.path.exists(qsb_source):
        return
        
    qsb_path = "/usr/lib/qt6/bin/qsb"
    if not os.path.exists(qsb_path):
        qsb_path = "qsb"
        
    import subprocess
    try:
        subprocess.run([qsb_path, "--qt6", "-o", qsb_output, qsb_source], check=True, capture_output=True)
    except Exception:
        pass

def main():
    compile_shader()
    
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Tomato Study")
    app.setOrganizationName("TomatoStudy")
    
    backend = TimerBackend()
    
    # Register clean shutdown slot
    app.aboutToQuit.connect(backend.cleanup)
    
    view = QQuickView()
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
