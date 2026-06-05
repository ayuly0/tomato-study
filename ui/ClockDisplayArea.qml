import QtQuick

Item {
    id: root
    anchors.fill: parent

    // UI State Properties
    property bool zenMode: false
    property bool controlsHiddenByInactivity: false
    property bool isHovered: false
    property color stateBreakColor: "#aaaaaa"
    
    // Backend Properties
    property string currentState: "work"
    property color themeColor: "#ffffff"
    property bool isRunning: false
    property int workCount: 0
    property int longBreakInterval: 4
    property string clockTheme: "digital"
    property string timeString: "00:00"

    // Status header
    Text {
        id: statusText
        anchors.top: parent.top
        anchors.topMargin: Math.max(30, parent.height * 0.12)
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
            if (root.currentState === "work") {
                return "FOCUS WORK";
            } else if (root.currentState === "short_break") {
                return "SHORT BREAK";
            } else {
                return "LONG BREAK";
            }
        }
        font.pixelSize: Math.max(11, Math.min(parent.width, parent.height) * 0.04)
        font.bold: true
        font.letterSpacing: 2
        color: root.currentState === "work" ? root.themeColor : root.stateBreakColor
        opacity: {
            if (root.zenMode || (root.isRunning && root.controlsHiddenByInactivity)) {
                return 0.05;
            }
            return (root.isHovered || !root.isRunning) ? 0.6 : 0.05;
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }
    }

    // Session Counter
    Text {
        id: sessionText
        anchors.top: statusText.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
            var current = (root.workCount % root.longBreakInterval) + 1;
            var total = root.longBreakInterval;
            if (root.currentState === "work") {
                return "SESSION " + current + "/" + total;
            } else {
                return "UP NEXT: SESSION " + current + "/" + total;
            }
        }
        font.pixelSize: Math.max(9, statusText.font.pixelSize * 0.75)
        font.bold: true
        font.letterSpacing: 2
        color: root.currentState === "work" ? root.themeColor : root.stateBreakColor
        opacity: statusText.opacity * 0.8
    }

    // 2.5D Split-Card Flip Clock Display
    FlipClock {
        id: flipClock
        anchors.centerIn: parent
        visible: root.clockTheme === "flip"
        timeString: root.timeString
        isRunning: root.isRunning
        referenceSize: Math.min(parent.width, parent.height)
    }

    // Simple Digital Clock Display
    DigitalClock {
        id: digitalClock
        anchors.centerIn: parent
        visible: root.clockTheme === "digital"
        timeString: root.timeString
        themeColor: root.themeColor
        referenceSize: Math.min(parent.width, parent.height)
    }
}
