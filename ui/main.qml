import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 350
    height: 400
    focus: true

    // State Colors mapping for status label and text theme matching
    readonly property color stateBreakColor: "#aaaaaa"
    readonly property color themeContrastColor: (timerBackend.themeColor === "#ffffff" || timerBackend.themeColor === "#f1c40f") ? "#000000" : "#ffffff"

    // Button & Layout Dimensions Constants
    readonly property int controlHeight: 30
    readonly property int controlRadius: 4
    readonly property int playPauseWidth: 70
    readonly property int resetWidth: 70
    readonly property int settingsWidth: 38
    readonly property int musicCollapsedWidth: 34
    readonly property int musicExpandedWidth: 140

    // Zen Mode and Inactivity states
    property bool zenMode: false
    property bool controlsHiddenByInactivity: false
    
    onZenModeChanged: {
        zenNotification.trigger();
    }
    
    Connections {
        target: timerBackend
        function onIsRunningChanged() {
            if (timerBackend.isRunning) {
                controlsHiddenByInactivity = false;
                controlsInteractionTimer.restart();
            }
        }
    }
    
    Timer {
        id: controlsInteractionTimer
        interval: 2500 // Hide after 2.5 seconds of stillness
        running: settingsPanel.opacity === 0.0
        repeat: false
        onTriggered: {
            controlsHiddenByInactivity = true;
        }
    }

    // Background is pitch black for absolute fallback focus
    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#000000"
    }


    BackgroundShader {
        id: bgShader
        damping: timerBackend.shaderDamping
        themeColor: timerBackend.themeColor
        shaderSpeed: timerBackend.shaderSpeed
        meteorFrequency: timerBackend.meteorFrequency
        isPaused: settingsPanel.opacity > 0.0
        targetX: hoverArea.mouseX / width
        targetY: hoverArea.mouseY / height
    }
    // Fullscreen click area to track background clicks and focus
    MouseArea {
        id: bgMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        
        onPressed: {
            // Wake up controls on click
            controlsInteractionTimer.restart();
            controlsHiddenByInactivity = false;
            root.focus = true;
        }
        
        onDoubleClicked: {
            zenMode = !zenMode;
        }
    }


    ClockDisplayArea {
        id: clockDisplay
        zenMode: root.zenMode
        controlsHiddenByInactivity: root.controlsHiddenByInactivity
        isHovered: hoverArea.containsMouse
        stateBreakColor: root.stateBreakColor
        
        currentState: timerBackend.currentState
        themeColor: timerBackend.themeColor
        isRunning: timerBackend.isRunning
        workCount: timerBackend.workCount
        longBreakInterval: timerBackend.longBreakInterval
        clockTheme: timerBackend.clockTheme
        timeString: timerBackend.timeString
    }

    ControlBar {
        id: controlBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(25, parent.height * 0.1)
        anchors.horizontalCenter: parent.horizontalCenter
        
        zenMode: root.zenMode
        controlsHiddenByInactivity: root.controlsHiddenByInactivity
        isHovered: hoverArea.containsMouse
        
        isRunning: timerBackend.isRunning
        streamEnabled: timerBackend.streamEnabled
        streamStatus: timerBackend.streamStatus
        songTitle: timerBackend.songTitle
        themeColor: timerBackend.themeColor
        soundEnabled: timerBackend.soundEnabled
        alarmVolume: timerBackend.alarmVolume
        streamVolume: timerBackend.streamVolume
        
        onPlayPauseClicked: {
            if (timerBackend.isRunning) timerBackend.pause();
            else timerBackend.start();
        }
        onResetClicked: timerBackend.reset()
        onSettingsClicked: root.openSettings()
        onToggleStreamClicked: timerBackend.toggleStream()
        onToggleMuteClicked: {
            timerBackend.updateSettings(
                timerBackend.workMinutes, timerBackend.shortBreakMinutes, timerBackend.longBreakMinutes,
                timerBackend.alwaysOnTop, !timerBackend.soundEnabled, timerBackend.flashEnabled,
                timerBackend.themeColor, timerBackend.shaderDamping, timerBackend.shaderSpeed,
                timerBackend.meteorFrequency, timerBackend.clockTheme, timerBackend.autoStartBreaks,
                timerBackend.autoStartWork, timerBackend.longBreakInterval, timerBackend.alarmVolume,
                timerBackend.tickingEnabled, timerBackend.streamEnabled, timerBackend.streamVolume
            );
        }
        onRequestAlarmVolume: (value) => timerBackend.setAlarmVolume(value)
        onRequestStreamVolume: (value) => timerBackend.setStreamVolume(value)
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        cursorShape: (zenMode || controlsHiddenByInactivity) ? Qt.BlankCursor : Qt.ArrowCursor
        
        onPositionChanged: (mouse) => {
            controlsInteractionTimer.restart();
            controlsHiddenByInactivity = false;
        }
    }

    SettingsPanel {
        id: settingsPanel
        themeColor: timerBackend.themeColor
        themeContrastColor: root.themeContrastColor
        
        onSaveRequested: (s) => {
            timerBackend.updateSettings(
                s.workMinutes, s.shortBreakMinutes, s.longBreakMinutes,
                s.alwaysOnTop, s.soundEnabled, s.flashEnabled,
                s.themeColor, s.shaderDamping, s.shaderSpeed,
                s.meteorFrequency, s.clockTheme, s.autoStartBreaks,
                s.autoStartWork, s.longBreakInterval, s.alarmVolume,
                s.tickingEnabled, s.streamEnabled, s.streamVolume
            );
        }
        
        onUpdateKeybindsRequested: (p1, p2, p3, p4, p5, p6) => {
            timerBackend.updateKeybinds(p1, p2, p3, p4, p5, p6);
        }
    }
    // Screen Flash Overlay layer
    Rectangle {
        id: flashOverlay
        anchors.fill: parent
        color: timerBackend.themeColor
        opacity: 0.0
        visible: opacity > 0.0
        
        SequentialAnimation {
            id: flashAnimation
            loops: 4
            
            NumberAnimation {
                target: flashOverlay
                property: "opacity"
                from: 0.0
                to: 0.5
                duration: 200
                easing.type: Easing.OutQuad
            }
            
            NumberAnimation {
                target: flashOverlay
                property: "opacity"
                from: 0.5
                to: 0.0
                duration: 250
                easing.type: Easing.InQuad
            }
        }
        
        Connections {
            target: timerBackend
            function onFlashScreen() {
                flashAnimation.start();
            }
        }
    }


    function openSettings() {
        var settings = {
            workMinutes: timerBackend.workMinutes,
            shortBreakMinutes: timerBackend.shortBreakMinutes,
            longBreakMinutes: timerBackend.longBreakMinutes,
            alwaysOnTop: timerBackend.alwaysOnTop,
            soundEnabled: timerBackend.soundEnabled,
            flashEnabled: timerBackend.flashEnabled,
            themeColor: timerBackend.themeColor,
            clockTheme: timerBackend.clockTheme,
            shaderDamping: timerBackend.shaderDamping,
            shaderSpeed: timerBackend.shaderSpeed,
            meteorFrequency: timerBackend.meteorFrequency,
            autoStartBreaks: timerBackend.autoStartBreaks,
            autoStartWork: timerBackend.autoStartWork,
            longBreakInterval: timerBackend.longBreakInterval,
            alarmVolume: timerBackend.alarmVolume,
            tickingEnabled: timerBackend.tickingEnabled,
            streamEnabled: timerBackend.streamEnabled,
            streamVolume: timerBackend.streamVolume,
            
            keybindPlayPause: timerBackend.keybindPlayPause,
            keybindReset: timerBackend.keybindReset,
            keybindSettings: timerBackend.keybindSettings,
            keybindZenMode: timerBackend.keybindZenMode,
            keybindStream: timerBackend.keybindStream,
            keybindMute: timerBackend.keybindMute
        };
        settingsPanel.open(settings);
    }
    // Zen Mode Status Notification Overlay
    Rectangle {
        id: zenNotification
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(15, parent.height * 0.05)
        width: 140
        height: 30
        color: "#161616"
        border.color: timerBackend.themeColor
        border.width: 1
        radius: 15
        opacity: 0.0
        visible: opacity > 0.0
        
        Text {
            id: zenNotificationText
            text: zenMode ? "ZEN FOCUS ON" : "ZEN FOCUS OFF"
            color: "#ffffff"
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
            anchors.centerIn: parent
        }
        
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        Timer {
            id: zenNotificationTimer
            interval: 1500
            running: false
            repeat: false
            onTriggered: zenNotification.opacity = 0.0
        }
        
        function trigger() {
            zenNotification.opacity = 0.85;
            zenNotificationTimer.restart();
        }
    }

    // Hotkey Controls
    Shortcut {
        sequence: timerBackend.keybindPlayPause
        onActivated: {
            if (timerBackend.isRunning) timerBackend.pause();
            else timerBackend.start();
        }
        enabled: settingsPanel.opacity === 0.0
    }
    Shortcut {
        sequence: timerBackend.keybindReset
        onActivated: timerBackend.reset()
        enabled: settingsPanel.opacity === 0.0
    }
    Shortcut {
        sequence: timerBackend.keybindSettings
        onActivated: {
            if (settingsPanel.opacity > 0.0) settingsPanel.opacity = 0.0;
            else openSettings();
        }
    }
    Shortcut {
        sequence: timerBackend.keybindZenMode
        onActivated: zenMode = !zenMode
        enabled: settingsPanel.opacity === 0.0
    }
    Shortcut {
        sequence: timerBackend.keybindStream
        onActivated: timerBackend.toggleStream()
        enabled: settingsPanel.opacity === 0.0
    }
    Shortcut {
        sequence: timerBackend.keybindMute
        onActivated: {
            timerBackend.updateSettings(
                timerBackend.workMinutes, timerBackend.shortBreakMinutes, timerBackend.longBreakMinutes,
                timerBackend.alwaysOnTop, !timerBackend.soundEnabled, timerBackend.flashEnabled,
                timerBackend.themeColor, timerBackend.shaderDamping, timerBackend.shaderSpeed,
                timerBackend.meteorFrequency, timerBackend.clockTheme, timerBackend.autoStartBreaks,
                timerBackend.autoStartWork, timerBackend.longBreakInterval, timerBackend.alarmVolume,
                timerBackend.tickingEnabled, timerBackend.streamEnabled, timerBackend.streamVolume
            );
        }
        enabled: settingsPanel.opacity === 0.0
    }
}
