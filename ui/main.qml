import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 350
    height: 400
    focus: true

    HoverHandler {
        id: globalHoverHandler
        onPointChanged: {
            controlsInteractionTimer.restart();
            controlsHiddenByInactivity = false;
        }
    }

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
    property bool isCompactMode: width < timerBackend.compactWidthThreshold || height < timerBackend.compactHeightThreshold
    
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
        targetX: root.width > 0 ? Math.max(0.0, Math.min(1.0, globalHoverHandler.point.position.x / root.width)) : 0.5
        targetY: root.height > 0 ? Math.max(0.0, Math.min(1.0, globalHoverHandler.point.position.y / root.height)) : 0.5
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
        isCompactMode: root.isCompactMode
        isHovered: globalHoverHandler.hovered
        stateBreakColor: root.stateBreakColor
        
        currentState: timerBackend.currentState
        themeColor: timerBackend.themeColor
        isRunning: timerBackend.isRunning
        workCount: timerBackend.workCount
        longBreakInterval: timerBackend.longBreakInterval
        clockTheme: timerBackend.clockTheme
        timeString: timerBackend.timeString
        clockScale: timerBackend.clockScale
        strictFocusActive: timerBackend.strictFocusActive
    }

    ControlBar {
        id: controlBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(25, parent.height * 0.1)
        anchors.horizontalCenter: parent.horizontalCenter
        
        
        zenMode: root.zenMode
        controlsHiddenByInactivity: root.controlsHiddenByInactivity
        isCompactMode: root.isCompactMode
        isHovered: globalHoverHandler.hovered
        
        isRunning: timerBackend.isRunning
        streamEnabled: timerBackend.streamEnabled
        streamMuted: timerBackend.streamMuted
        streamStatus: timerBackend.streamStatus
        songTitle: timerBackend.songTitle
        themeColor: timerBackend.themeColor
        soundEnabled: timerBackend.soundEnabled
        alarmVolume: timerBackend.alarmVolume
        streamVolume: timerBackend.streamVolume
        timerMode: timerBackend.timerMode
        currentState: timerBackend.currentState
        
        onPlayPauseClicked: {
            if (timerBackend.isRunning) timerBackend.pause();
            else timerBackend.start();
        }
        onResetClicked: timerBackend.reset()
        onSettingsClicked: root.openSettings()
        onToggleStreamClicked: timerBackend.toggleStream()
        onToggleMuteClicked: {
            timerBackend.updateSettings({ "soundEnabled": !timerBackend.soundEnabled });
        }
        onRequestAlarmVolume: (value) => timerBackend.setAlarmVolume(value)
        onRequestStreamVolume: (value) => timerBackend.setStreamVolume(value)
        onTakeBreakClicked: timerBackend.stopFlowtimeAndStartBreak()
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        cursorShape: (zenMode || controlsHiddenByInactivity) ? Qt.BlankCursor : Qt.ArrowCursor
    }

    SettingsPanel {
        id: settingsPanel
        themeColor: timerBackend.themeColor
        themeContrastColor: root.themeContrastColor
        
        onSaveRequested: (s) => {
            timerBackend.updateSettings(s);
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
            activePreset: timerBackend.activePreset,
            timerMode: timerBackend.timerMode,
            
            keybindPlayPause: timerBackend.keybindPlayPause,
            keybindReset: timerBackend.keybindReset,
            keybindSettings: timerBackend.keybindSettings,
            keybindZenMode: timerBackend.keybindZenMode,
            keybindStream: timerBackend.keybindStream,
            keybindMute: timerBackend.keybindMute,
            strictFocusEnabled: timerBackend.strictFocusEnabled,
            privacyLockEnabled: timerBackend.privacyLockEnabled,
            encryptStorage: timerBackend.encryptStorage,
            compactWidthThreshold: timerBackend.compactWidthThreshold,
            compactHeightThreshold: timerBackend.compactHeightThreshold,
            clockScale: timerBackend.clockScale
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

    // Security Alert Toast Overlay
    Rectangle {
        id: securityToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(15, parent.height * 0.05)
        width: Math.min(parent.width - 40, securityToastText.implicitWidth + 30)
        height: 32
        color: "#221111"
        border.color: "#ff4d4d"
        border.width: 1
        radius: 16
        opacity: 0.0
        visible: opacity > 0.0
        z: 999
        
        Text {
            id: securityToastText
            text: ""
            color: "#ffcccc"
            font.pixelSize: 11
            font.bold: true
            anchors.centerIn: parent
            elide: Text.ElideRight
            maximumLineCount: 1
        }
        
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        Timer {
            id: securityToastTimer
            interval: 3000
            running: false
            repeat: false
            onTriggered: securityToast.opacity = 0.0
        }
        
        function showMessage(msg) {
            securityToastText.text = msg;
            securityToast.opacity = 0.95;
            securityToastTimer.restart();
        }
    }

    Connections {
        target: timerBackend
        function onSecurityAlert(msg) {
            securityToast.showMessage(msg);
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
            timerBackend.updateSettings({ "soundEnabled": !timerBackend.soundEnabled });
        }
        enabled: settingsPanel.opacity === 0.0
    }
}
