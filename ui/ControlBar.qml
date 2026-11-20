import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    // UI State
    property bool zenMode: false
    property bool controlsHiddenByInactivity: false
    property bool isHovered: false
    property bool isCompactMode: false
    
    // Timer State
    property bool isRunning: false
    property bool streamEnabled: false
    property bool streamMuted: false
    property string streamStatus: "disconnected"
    property string songTitle: ""
    property color themeColor: "#ffffff"
    property bool soundEnabled: true
    property real alarmVolume: 0.5
    property real streamVolume: 0.5
    property string timerMode: "countdown"
    property string currentState: "work"

    // Button & Layout Dimensions Constants
    readonly property int controlHeight: 30
    readonly property int controlRadius: 4
    readonly property int playPauseWidth: 70
    readonly property int resetWidth: 70
    readonly property int settingsWidth: 38
    readonly property int musicCollapsedWidth: 34
    readonly property int musicExpandedWidth: 140

    // Signals to Backend/Main
    signal playPauseClicked()
    signal resetClicked()
    signal settingsClicked()
    signal toggleStreamClicked()
    signal toggleMuteClicked()
    signal requestAlarmVolume(real value)
    signal requestStreamVolume(real value)
    signal takeBreakClicked()

    width: Math.max(controlsRow.width, 240)
    height: controlsRow.height + 22

    visible: opacity > 0.0
    opacity: {
        if (root.zenMode) return 0.0;
        if (root.isCompactMode && !root.isHovered) return 0.0;
        if (root.isRunning && root.controlsHiddenByInactivity) return 0.0;
        return (root.isHovered || !root.isRunning) ? 1.0 : 0.0;
    }
    
    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }

    // Active Streaming Status text above buttons
    Text {
        id: streamStatusText
        anchors.bottom: controlsRow.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
            if (!root.streamEnabled) return "";
            if (root.streamStatus === "buffering") return "BUFFERING LATE.SH VIBE RADIO...";
            if (root.streamStatus === "playing") {
                if (root.songTitle !== "") {
                    return "AUDIO: " + root.songTitle.toUpperCase();
                }
                return "PLAYING LATE.SH VIBE RADIO";
            }
            if (root.streamStatus === "error") return "STREAM CONNECTION ERROR";
            return "STREAM CONNECTED";
        }
        color: root.themeColor
        font.pixelSize: 9
        font.bold: true
        font.letterSpacing: 1
        opacity: {
            if (root.zenMode || (root.isRunning && root.controlsHiddenByInactivity)) {
                return 0.0;
            }
            return 0.75;
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Row {
        id: controlsRow
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16
        
        // Play/Pause Button
        Rectangle {
            id: playPauseButton
            width: (root.timerMode === "flowtime" && root.currentState === "work") ? 100 : root.playPauseWidth
            height: root.controlHeight
            radius: root.controlRadius
            color: playMouse.containsMouse ? "#222222" : "#111111"
            border.color: playMouse.containsMouse ? root.themeColor : "#333333"
            border.width: 1
            
            Text {
                text: {
                    if (root.timerMode === "flowtime" && root.currentState === "work") {
                        return root.isRunning ? "PAUSE FOCUS" : "START FOCUS";
                    }
                    return root.isRunning ? "PAUSE" : "START";
                }
                color: "#ffffff"
                anchors.centerIn: parent
                font.pixelSize: 11
                font.bold: true
            }
            
            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.playPauseClicked()
            }
        }
        
        // Take Break Button (Flowtime only)
        Rectangle {
            id: takeBreakButton
            width: 90
            height: root.controlHeight
            radius: root.controlRadius
            color: takeBreakMouse.containsMouse ? "#222222" : "#111111"
            border.color: takeBreakMouse.containsMouse ? root.themeColor : "#333333"
            border.width: 1
            visible: root.timerMode === "flowtime" && root.currentState === "work"
            
            Text {
                text: "TAKE BREAK"
                color: "#ffffff"
                anchors.centerIn: parent
                font.pixelSize: 11
                font.bold: true
            }
            
            MouseArea {
                id: takeBreakMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.takeBreakClicked()
            }
        }
        
        // Reset Button
        Rectangle {
            width: root.resetWidth
            height: root.controlHeight
            radius: root.controlRadius
            color: resetMouse.containsMouse ? "#222222" : "#111111"
            border.color: resetMouse.containsMouse ? root.themeColor : "#333333"
            border.width: 1
            
            Text {
                text: "RESET"
                color: "#ffffff"
                anchors.centerIn: parent
                font.pixelSize: 11
                font.bold: true
            }
            
            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.resetClicked()
            }
        }
        
        // Settings Button
        Rectangle {
            width: root.settingsWidth
            height: root.controlHeight
            radius: root.controlRadius
            color: settingsMouse.containsMouse ? "#222222" : "#111111"
            border.color: settingsMouse.containsMouse ? root.themeColor : "#333333"
            border.width: 1
            
            Text {
                text: timerBackend.icon("gear")
                font.family: timerBackend.iconFontFamily
                font.pixelSize: 13
                color: settingsMouse.containsMouse ? root.themeColor : "#ffffff"
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.settingsClicked()
            }
        }

        // Volume Control Button
        Rectangle {
            id: volumeButton
            width: (volumeHoverArea.containsMouse || miniVolumeSlider.hovered) ? root.musicExpandedWidth : root.musicCollapsedWidth
            height: root.controlHeight
            radius: root.controlRadius
            color: (volumeHoverArea.containsMouse || miniVolumeSlider.hovered) ? "#1c1c1c" : "#111111"
            border.color: (root.streamEnabled && !root.streamMuted) ? root.themeColor : "#333333"
            border.width: 1
            clip: true
            
            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
            }
            
            MouseArea {
                id: volumeHoverArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: (mouse) => {
                    if (volumeButton.width <= root.musicCollapsedWidth || mouse.x < root.musicCollapsedWidth) {
                        root.toggleStreamClicked();
                    }
                }
            }

            // Left icon container
            Item {
                id: volumeIconContainer
                width: root.musicCollapsedWidth
                height: parent.height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: staticIcon
                    text: (root.streamEnabled && !root.streamMuted) ? timerBackend.icon("volume-high") : timerBackend.icon("volume-xmark")
                    font.family: timerBackend.iconFontFamily
                    font.pixelSize: 13
                    color: (root.streamEnabled && !root.streamMuted) ? root.themeColor : "#888888"
                    anchors.centerIn: parent
                }
            }

            // Volume slider
            Slider {
                id: miniVolumeSlider
                from: 0.0
                to: 1.0
                value: root.streamVolume
                stepSize: 0.05
                width: 90
                anchors.left: volumeIconContainer.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                
                opacity: volumeButton.width > root.musicCollapsedWidth ? 1.0 : 0.0
                visible: opacity > 0.0
                
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
                
                onMoved: {
                    root.requestStreamVolume(value);
                }
                
                background: Rectangle {
                    x: miniVolumeSlider.leftPadding
                    y: miniVolumeSlider.topPadding + miniVolumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 90
                    implicitHeight: 2
                    width: miniVolumeSlider.availableWidth
                    height: implicitHeight
                    radius: 1
                    color: "#333333"
                    
                    Rectangle {
                        width: miniVolumeSlider.visualPosition * parent.width
                        height: parent.height
                        color: root.themeColor
                        radius: 1
                    }
                }
                
                handle: Rectangle {
                    x: miniVolumeSlider.leftPadding + miniVolumeSlider.visualPosition * (miniVolumeSlider.availableWidth - width)
                    y: miniVolumeSlider.topPadding + miniVolumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: "#ffffff"
                    border.color: root.themeColor
                    border.width: 1
                }
            }
        }
    }
}
