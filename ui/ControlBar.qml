import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    // UI State
    property bool zenMode: false
    property bool controlsHiddenByInactivity: false
    property bool isHovered: false
    
    // Timer State
    property bool isRunning: false
    property bool streamEnabled: false
    property string streamStatus: "disconnected"
    property string songTitle: ""
    property color themeColor: "#ffffff"
    property bool soundEnabled: true
    property real alarmVolume: 0.5
    property real streamVolume: 0.5

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

    width: Math.max(controlsRow.width, 240)
    height: controlsRow.height + 22

    visible: opacity > 0.0
    opacity: {
        if (root.zenMode) return 0.0;
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
                    return "♫ " + root.songTitle.toUpperCase();
                }
                return "♫ PLAYING LATE.SH VIBE RADIO";
            }
            if (root.streamStatus === "error") return "⚠ STREAM CONNECTION ERROR";
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
        
        // Play/Pause Button (Expanding)
        Rectangle {
            id: playPauseButton
            width: (playMouse.containsMouse || miniAlarmVolumeSlider.hovered || muteMouse.containsMouse) ? 200 : root.playPauseWidth
            height: root.controlHeight
            radius: root.controlRadius
            color: (playMouse.containsMouse || miniAlarmVolumeSlider.hovered || muteMouse.containsMouse) ? "#1c1c1c" : "#111111"
            border.color: (playMouse.containsMouse || miniAlarmVolumeSlider.hovered || muteMouse.containsMouse) ? root.themeColor : "#333333"
            border.width: 1
            clip: true
            
            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
            }
            
            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: (mouse) => {
                    if (playPauseButton.width <= root.playPauseWidth || mouse.x < root.playPauseWidth) {
                        root.playPauseClicked();
                    }
                }
            }
            
            Item {
                id: playTextContainer
                width: root.playPauseWidth
                height: parent.height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                
                Text {
                    text: root.isRunning ? "PAUSE" : "START"
                    color: "#ffffff"
                    anchors.centerIn: parent
                    font.pixelSize: 11
                    font.bold: true
                }
            }
            
            // Mute/Unmute SVG Button
            Image {
                id: muteIcon
                source: root.soundEnabled ? "file:ui/volume-up.svg" : "file:ui/volume-mute.svg"
                width: 16
                height: 16
                anchors.left: playTextContainer.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                opacity: playPauseButton.width > root.playPauseWidth ? 1.0 : 0.0
                visible: opacity > 0.0
                
                Behavior on opacity { NumberAnimation { duration: 150 } }
                
                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    onClicked: {
                        root.toggleMuteClicked();
                    }
                }
            }
            
            // Volume slider for alarm volume
            Slider {
                id: miniAlarmVolumeSlider
                from: 0.0
                to: 1.0
                value: root.alarmVolume
                stepSize: 0.05
                width: 80
                anchors.left: muteIcon.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                
                opacity: playPauseButton.width > root.playPauseWidth ? 1.0 : 0.0
                visible: opacity > 0.0
                
                Behavior on opacity { NumberAnimation { duration: 150 } }
                
                onMoved: {
                    root.requestAlarmVolume(value);
                }
                
                background: Rectangle {
                    x: miniAlarmVolumeSlider.leftPadding
                    y: miniAlarmVolumeSlider.topPadding + miniAlarmVolumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 80
                    implicitHeight: 2
                    width: miniAlarmVolumeSlider.availableWidth
                    height: implicitHeight
                    radius: 1
                    color: "#333333"
                    
                    Rectangle {
                        width: miniAlarmVolumeSlider.visualPosition * parent.width
                        height: parent.height
                        color: root.themeColor
                        radius: 1
                    }
                }
                
                handle: Rectangle {
                    x: miniAlarmVolumeSlider.leftPadding + miniAlarmVolumeSlider.visualPosition * (miniAlarmVolumeSlider.availableWidth - width)
                    y: miniAlarmVolumeSlider.topPadding + miniAlarmVolumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5
                    color: "#ffffff"
                    border.color: root.themeColor
                    border.width: 1
                }
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
                text: "⚙"
                color: "#ffffff"
                anchors.centerIn: parent
                font.pixelSize: 15
            }
            
            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.settingsClicked()
            }
        }

        // Music / Stream Control Button
        Rectangle {
            id: musicButton
            width: (musicHoverArea.containsMouse || miniVolumeSlider.hovered) ? root.musicExpandedWidth : root.musicCollapsedWidth
            height: root.controlHeight
            radius: root.controlRadius
            color: (musicHoverArea.containsMouse || miniVolumeSlider.hovered) ? "#1c1c1c" : "#111111"
            border.color: root.streamEnabled ? root.themeColor : "#333333"
            border.width: 1
            clip: true
            
            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
            }
            
            MouseArea {
                id: musicHoverArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: (mouse) => {
                    if (musicButton.width <= root.musicCollapsedWidth || mouse.x < root.musicCollapsedWidth) {
                        root.toggleStreamClicked();
                    }
                }
            }

            // Left icon container
            Item {
                id: musicIconContainer
                width: root.musicCollapsedWidth
                height: parent.height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                // Static play/pause/error icon
                Text {
                    id: staticIcon
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: {
                        if (root.streamEnabled && root.streamStatus === "error") return "⚠";
                        if (root.streamEnabled && root.streamStatus === "playing") return "⏸";
                        return "⏵";
                    }
                    color: root.streamEnabled ? root.themeColor : "#888888"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "sans-serif"
                    visible: !(root.streamEnabled && root.streamStatus === "buffering")
                }

                // Rotating buffer icon
                Text {
                    id: spinnerIcon
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "↻"
                    color: root.themeColor
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "sans-serif"
                    visible: root.streamEnabled && root.streamStatus === "buffering"
                    
                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1200
                        running: spinnerIcon.visible
                        loops: Animation.Infinite
                    }
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
                anchors.left: musicIconContainer.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                
                opacity: musicButton.width > root.musicCollapsedWidth ? 1.0 : 0.0
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
