import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 350
    height: 400
    focus: true

    // State Colors mapping for status label and text theme matching
    readonly property color stateBreakColor: "#aaaaaa"

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

    // Interactive GLSL Shader Background
    ShaderEffect {
        id: shaderEffect
        anchors.fill: parent
        
        property real targetX: 0.5
        property real targetY: 0.5
        property real currentX: 0.5
        property real currentY: 0.5
        property real damping: timerBackend.shaderDamping
        
        property point mouse: Qt.point(0.5, 0.5)
        property real time: 0.0
        property color themeColor: timerBackend.themeColor
        property real aspect: width / height
        property real shaderSpeed: timerBackend.shaderSpeed
        property real meteorFrequency: timerBackend.meteorFrequency
        
        // Disable rendering when settings panel is open to save CPU/GPU resources
        visible: opacity > 0.0
        opacity: (settingsPanel.opacity > 0.0) ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        fragmentShader: "shader.frag.qsb"
    }

    // Animation physics and time increment loop
    Timer {
        id: shaderTimer
        interval: 16 // Ticks at ~60fps
        running: settingsPanel.opacity === 0.0 // Pause rendering when settings panel is open
        repeat: true
        onTriggered: {
            shaderEffect.currentX += (shaderEffect.targetX - shaderEffect.currentX) * shaderEffect.damping;
            shaderEffect.currentY += (shaderEffect.targetY - shaderEffect.currentY) * shaderEffect.damping;
            shaderEffect.mouse = Qt.point(shaderEffect.currentX, shaderEffect.currentY);
            shaderEffect.time += 0.016;
        }
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

    // Main Clock and Label Layout
    Item {
        anchors.fill: parent
        
        // Status header
        Text {
            id: statusText
            anchors.top: parent.top
            anchors.topMargin: Math.max(30, parent.height * 0.12)
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (timerBackend.currentState === "work") {
                    return "FOCUS WORK";
                } else if (timerBackend.currentState === "short_break") {
                    return "SHORT BREAK";
                } else {
                    return "LONG BREAK";
                }
            }
            font.pixelSize: Math.max(11, Math.min(parent.width, parent.height) * 0.04)
            font.bold: true
            font.letterSpacing: 2
            color: timerBackend.currentState === "work" ? timerBackend.themeColor : stateBreakColor
            opacity: {
                if (zenMode || (timerBackend.isRunning && controlsHiddenByInactivity)) {
                    return 0.05;
                }
                return (hoverArea.containsMouse || !timerBackend.isRunning) ? 0.6 : 0.05;
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
            }
        }

        // 2.5D Split-Card Flip Clock Display
        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 8

            FlipDigit {
                id: minTensCard
                width: Math.min(root.width, root.height) * 0.16
                height: width * 1.4
                value: timerBackend.timeString.charAt(0)
            }
            
            FlipDigit {
                id: minOnesCard
                width: minTensCard.width
                height: minTensCard.height
                value: timerBackend.timeString.charAt(1)
            }
            
            Text {
                id: colonText
                text: ":"
                color: "#ffffff"
                font.pixelSize: minTensCard.height * 0.65
                font.bold: true
                font.family: "Courier New"
                anchors.verticalCenter: parent.verticalCenter
                
                Timer {
                    interval: 1000
                    running: timerBackend.isRunning
                    repeat: true
                    onTriggered: colonText.opacity = colonText.opacity === 1.0 ? 0.30 : 1.0
                }
                onOpacityChanged: if (!timerBackend.isRunning) opacity = 1.0;
            }

            FlipDigit {
                id: secTensCard
                width: minTensCard.width
                height: minTensCard.height
                value: timerBackend.timeString.charAt(3)
            }
            
            FlipDigit {
                id: secOnesCard
                width: minTensCard.width
                height: minTensCard.height
                value: timerBackend.timeString.charAt(4)
            }
        }
    }

    // Hover Controls Overlay (Bottom)
    Item {
        id: controlsContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(25, parent.height * 0.1)
        anchors.horizontalCenter: parent.horizontalCenter
        width: controlsRow.width
        height: controlsRow.height
        
        // Hidden in Zen mode, or when mouse is inactive (if running)
        visible: opacity > 0.0
        opacity: {
            if (zenMode) return 0.0;
            if (timerBackend.isRunning && controlsHiddenByInactivity) return 0.0;
            return (hoverArea.containsMouse || !timerBackend.isRunning) ? 1.0 : 0.0;
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }

        Row {
            id: controlsRow
            spacing: 16
            
            // Play/Pause Button
            Rectangle {
                width: 76
                height: 34
                radius: 4
                color: playMouse.containsMouse ? "#222222" : "#111111"
                border.color: playMouse.containsMouse ? timerBackend.themeColor : "#333333"
                border.width: 1
                
                Text {
                    text: timerBackend.isRunning ? "PAUSE" : "START"
                    color: "#ffffff"
                    anchors.centerIn: parent
                    font.pixelSize: 11
                    font.bold: true
                }
                
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (timerBackend.isRunning) {
                            timerBackend.pause();
                        } else {
                            timerBackend.start();
                        }
                    }
                }
            }
            
            // Reset Button
            Rectangle {
                width: 76
                height: 34
                radius: 4
                color: resetMouse.containsMouse ? "#222222" : "#111111"
                border.color: resetMouse.containsMouse ? timerBackend.themeColor : "#333333"
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
                    onClicked: timerBackend.reset()
                }
            }
            
            // Settings Button
            Rectangle {
                width: 44
                height: 34
                radius: 4
                color: settingsMouse.containsMouse ? "#222222" : "#111111"
                border.color: settingsMouse.containsMouse ? timerBackend.themeColor : "#333333"
                border.width: 1
                
                Text {
                    text: "⚙"
                    color: "#ffffff"
                    anchors.centerIn: parent
                    font.pixelSize: 16
                }
                
                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openSettings()
                }
            }
        }
    }


    // Hover area covering whole window to control cursor hiding and layout show/hide transitions
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        // BlankCursor hides the mouse cursor when Zen mode is active or when inactive
        cursorShape: (zenMode || controlsHiddenByInactivity) ? Qt.BlankCursor : Qt.ArrowCursor
        
        onPositionChanged: (mouse) => {
            shaderEffect.targetX = mouse.x / width;
            shaderEffect.targetY = mouse.y / height;
            
            // Wake up controls and cursor on movement
            controlsInteractionTimer.restart();
            controlsHiddenByInactivity = false;
        }
    }
    // Slide/Fade Settings Overlay Panel
    Rectangle {
        id: settingsPanel
        anchors.fill: parent
        color: "#0a0a0a"
        opacity: 0.0
        visible: opacity > 0.0
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        MouseArea {
            anchors.fill: parent
        }

        // Fixed Header
        Column {
            id: settingsHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 12

            Text {
                text: "SETTINGS"
                color: "#ffffff"
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 3
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#222222"
            }
        }

        // Fixed Footer Buttons (Save / Cancel)
        Row {
            id: settingsFooter
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 20
            spacing: 16
            
            Rectangle {
                width: 90
                height: 32
                radius: 3
                color: cancelMouse.containsMouse ? "#222222" : "#121212"
                border.color: "#333333"
                border.width: 1
                
                Text {
                    text: "CANCEL"
                    color: "#aaaaaa"
                    anchors.centerIn: parent
                    font.pixelSize: 11
                    font.bold: true
                }
                
                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: settingsPanel.opacity = 0.0
                }
            }
            
            Rectangle {
                width: 110
                height: 32
                radius: 3
                color: saveMouse.containsMouse ? "#ffffff" : "#eeeeee"
                
                Text {
                    text: "SAVE & APPLY"
                    color: "#000000"
                    anchors.centerIn: parent
                    font.pixelSize: 11
                    font.bold: true
                }
                
                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        var w = parseInt(workInput.text) || 25;
                        var b = parseInt(breakInput.text) || 5;
                        var lb = parseInt(longBreakInput.text) || 15;
                        var lbi = parseInt(lbiInput.text) || 4;
                        if (w < 1) w = 1;
                        if (b < 1) b = 1;
                        if (lb < 1) lb = 1;
                        if (lbi < 1) lbi = 1;
                        
                        timerBackend.updateSettings(
                            w, b, lb,
                            aotToggle.checked,
                            soundToggle.checked,
                            flashToggle.checked,
                            colorRow.selectedColor,
                            dampingSlider.value,
                            speedSlider.value,
                            meteorSlider.value,
                            autoBreaksToggle.checked,
                            autoWorkToggle.checked,
                            lbi,
                            volumeSlider.value,
                            tickingToggle.checked,
                            streamToggle.checked,
                            streamVolumeSlider.value
                        );
                        settingsPanel.opacity = 0.0;
                    }
                }
            }
        }

        // Scrollable Settings List
        ScrollView {
            id: settingsScroll
            anchors.top: settingsHeader.bottom
            anchors.bottom: settingsFooter.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 4
            anchors.bottomMargin: 12
            clip: true

            Column {
                width: settingsScroll.width - 12
                spacing: 16

                // 1. Durations Group
                Column {
                    width: parent.width
                    spacing: 12
                    
                    // Work
                    Item {
                        width: parent.width
                        height: 26
                        
                        Text {
                            text: "Work Duration (min)"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Rectangle {
                            width: 70
                            height: 26
                            color: "#181818"
                            border.color: workInput.activeFocus ? timerBackend.themeColor : "#333333"
                            radius: 3
                            anchors.right: parent.right
                            
                            TextInput {
                                id: workInput
                                anchors.fill: parent
                                anchors.margins: 3
                                color: "#ffffff"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                validator: IntValidator { bottom: 1; top: 999 }
                            }
                        }
                    }
                    
                    // Short Break
                    Item {
                        width: parent.width
                        height: 26
                        
                        Text {
                            text: "Short Break (min)"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Rectangle {
                            width: 70
                            height: 26
                            color: "#181818"
                            border.color: breakInput.activeFocus ? timerBackend.themeColor : "#333333"
                            radius: 3
                            anchors.right: parent.right
                            
                            TextInput {
                                id: breakInput
                                anchors.fill: parent
                                anchors.margins: 3
                                color: "#ffffff"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                validator: IntValidator { bottom: 1; top: 999 }
                            }
                        }
                    }
                    
                    // Long Break
                    Item {
                        width: parent.width
                        height: 26
                        
                        Text {
                            text: "Long Break (min)"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Rectangle {
                            width: 70
                            height: 26
                            color: "#181818"
                            border.color: longBreakInput.activeFocus ? timerBackend.themeColor : "#333333"
                            radius: 3
                            anchors.right: parent.right
                            
                            TextInput {
                                id: longBreakInput
                                anchors.fill: parent
                                anchors.margins: 3
                                color: "#ffffff"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                validator: IntValidator { bottom: 1; top: 999 }
                            }
                        }
                    }

                    // Long Break Interval
                    Item {
                        width: parent.width
                        height: 26
                        
                        Text {
                            text: "Long Break Interval (cycles)"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Rectangle {
                            width: 70
                            height: 26
                            color: "#181818"
                            border.color: lbiInput.activeFocus ? timerBackend.themeColor : "#333333"
                            radius: 3
                            anchors.right: parent.right
                            
                            TextInput {
                                id: lbiInput
                                anchors.fill: parent
                                anchors.margins: 3
                                color: "#ffffff"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                validator: IntValidator { bottom: 1; top: 99 }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1b1b1b"
                }

                // 2. Toggles Group
                Column {
                    width: parent.width
                    spacing: 14
                    
                    // Always on top toggle
                    Item {
                        width: parent.width
                        height: 20
                        
                        Text {
                            text: "Always on Top"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Item {
                            id: aotToggle
                            width: 38
                            height: 20
                            anchors.right: parent.right
                            property bool checked: false
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: aotToggle.checked ? timerBackend.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: aotToggle.checked ? 20 : 4
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: aotToggle.checked = !aotToggle.checked
                            }
                        }
                    }

                    // Sound enabled toggle
                    Item {
                        width: parent.width
                        height: 20
                        
                        Text {
                            text: "Audible Alarm"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Item {
                            id: soundToggle
                            width: 38
                            height: 20
                            anchors.right: parent.right
                            property bool checked: false
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: soundToggle.checked ? timerBackend.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: soundToggle.checked ? 20 : 4
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: soundToggle.checked = !soundToggle.checked
                            }
                        }
                    }

                    // Visual flash toggle
                    Item {
                        width: parent.width
                        height: 20
                        
                        Text {
                            text: "Screen Flash on End"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Item {
                            id: flashToggle
                            width: 38
                            height: 20
                            anchors.right: parent.right
                            property bool checked: false
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: flashToggle.checked ? timerBackend.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: flashToggle.checked ? 20 : 4
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: flashToggle.checked = !flashToggle.checked
                            }
                        }
                    }

                    // Auto-Start Breaks toggle
                    Item {
                        width: parent.width
                        height: 20
                        
                        Text {
                            text: "Auto-Start Breaks"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Item {
                            id: autoBreaksToggle
                            width: 38
                            height: 20
                            anchors.right: parent.right
                            property bool checked: false
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: autoBreaksToggle.checked ? timerBackend.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: autoBreaksToggle.checked ? 20 : 4
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: autoBreaksToggle.checked = !autoBreaksToggle.checked
                            }
                        }
                    }

                    // Auto-Start Work toggle
                    Item {
                        width: parent.width
                        height: 20
                        
                        Text {
                            text: "Auto-Start Work"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Item {
                            id: autoWorkToggle
                            width: 38
                            height: 20
                            anchors.right: parent.right
                            property bool checked: false
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: autoWorkToggle.checked ? timerBackend.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: autoWorkToggle.checked ? 20 : 4
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: autoWorkToggle.checked = !autoWorkToggle.checked
                            }
                        }
                    }

                    // Soft Ticking Sound toggle
                    Item {
                        width: parent.width
                        height: 20
                        
                        Text {
                            text: "Soft Ticking Sound"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Item {
                            id: tickingToggle
                            width: 38
                            height: 20
                            anchors.right: parent.right
                            property bool checked: false
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: tickingToggle.checked ? timerBackend.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: tickingToggle.checked ? 20 : 4
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: tickingToggle.checked = !tickingToggle.checked
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1b1b1b"
                }

                // 3. Audio Volume Slider
                Item {
                    width: parent.width
                    height: 26
                    
                    Text {
                        text: "Alarm Volume (" + (volumeSlider.value * 100).toFixed(0) + "%)"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        id: volumeSlider
                        from: 0.0
                        to: 1.0
                        stepSize: 0.05
                        width: 120
                        anchors.right: parent.right
                        
                        background: Rectangle {
                            x: volumeSlider.leftPadding
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 120
                            implicitHeight: 4
                            width: volumeSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#333333"
                            
                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: timerBackend.themeColor
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: "#ffffff"
                            border.color: timerBackend.themeColor
                            border.width: 1
                        }
                    }
                }

                // Stream late.sh toggle
                Item {
                    width: parent.width
                    height: 20
                    
                    Text {
                        text: "Stream late.sh"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Item {
                        id: streamToggle
                        width: 38
                        height: 20
                        anchors.right: parent.right
                        property bool checked: false
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: streamToggle.checked ? timerBackend.themeColor : "#333333"
                             Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: streamToggle.checked ? 20 : 4
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: streamToggle.checked = !streamToggle.checked
                        }
                    }
                }

                // Stream Volume Slider
                Item {
                    width: parent.width
                    height: 26
                    
                    Text {
                        text: "Stream Volume (" + (streamVolumeSlider.value * 100).toFixed(0) + "%)"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        id: streamVolumeSlider
                        from: 0.0
                        to: 1.0
                        stepSize: 0.05
                        width: 120
                        anchors.right: parent.right
                        
                        background: Rectangle {
                            x: streamVolumeSlider.leftPadding
                            y: streamVolumeSlider.topPadding + streamVolumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 120
                            implicitHeight: 4
                            width: streamVolumeSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#333333"
                            
                            Rectangle {
                                width: streamVolumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: timerBackend.themeColor
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: streamVolumeSlider.leftPadding + streamVolumeSlider.visualPosition * (streamVolumeSlider.availableWidth - width)
                            y: streamVolumeSlider.topPadding + streamVolumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: "#ffffff"
                            border.color: timerBackend.themeColor
                            border.width: 1
                        }
                    }
                }

                // 4. Shader Sliders
                Item {
                    width: parent.width
                    height: 26
                    
                    Text {
                        text: "Shader Trail Delay (" + dampingSlider.value.toFixed(2) + ")"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        id: dampingSlider
                        from: 0.01
                        to: 0.20
                        stepSize: 0.01
                        width: 120
                        anchors.right: parent.right
                        
                        background: Rectangle {
                            x: dampingSlider.leftPadding
                            y: dampingSlider.topPadding + dampingSlider.availableHeight / 2 - height / 2
                            implicitWidth: 120
                            implicitHeight: 4
                            width: dampingSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#333333"
                            
                            Rectangle {
                                width: dampingSlider.visualPosition * parent.width
                                height: parent.height
                                color: timerBackend.themeColor
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: dampingSlider.leftPadding + dampingSlider.visualPosition * (dampingSlider.availableWidth - width)
                            y: dampingSlider.topPadding + dampingSlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: "#ffffff"
                            border.color: timerBackend.themeColor
                            border.width: 1
                        }
                    }
                }

                // Shader Drift Speed (Speed Slider)
                Item {
                    width: parent.width
                    height: 26
                    
                    Text {
                        text: "Star Drift Speed (" + (speedSlider.value * 1000).toFixed(0) + ")"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        id: speedSlider
                        from: 0.00
                        to: 0.05
                        stepSize: 0.005
                        width: 120
                        anchors.right: parent.right
                        
                        background: Rectangle {
                            x: speedSlider.leftPadding
                            y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                            implicitWidth: 120
                            implicitHeight: 4
                            width: speedSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#333333"
                            
                            Rectangle {
                                width: speedSlider.visualPosition * parent.width
                                height: parent.height
                                color: timerBackend.themeColor
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                            y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: "#ffffff"
                            border.color: timerBackend.themeColor
                            border.width: 1
                        }
                    }
                }

                // Shooting Star Frequency (Meteor Slider)
                Item {
                    width: parent.width
                    height: 26
                    
                    Text {
                        text: "Shooting Stars (" + (meteorSlider.value * 100).toFixed(0) + "%)"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        id: meteorSlider
                        from: 0.0
                        to: 1.0
                        stepSize: 0.1
                        width: 120
                        anchors.right: parent.right
                        
                        background: Rectangle {
                            x: meteorSlider.leftPadding
                            y: meteorSlider.topPadding + meteorSlider.availableHeight / 2 - height / 2
                            implicitWidth: 120
                            implicitHeight: 4
                            width: meteorSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#333333"
                            
                            Rectangle {
                                width: meteorSlider.visualPosition * parent.width
                                height: parent.height
                                color: timerBackend.themeColor
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: meteorSlider.leftPadding + meteorSlider.visualPosition * (meteorSlider.availableWidth - width)
                            y: meteorSlider.topPadding + meteorSlider.availableHeight / 2 - height / 2
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: "#ffffff"
                            border.color: timerBackend.themeColor
                            border.width: 1
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1b1b1b"
                }

                // 5. Theme Colors row
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Accent Color"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Row {
                        id: colorRow
                        spacing: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        property string selectedColor: timerBackend.themeColor
                        
                        readonly property var colorPalette: ["#ff4d4d", "#2ecc71", "#3498db", "#f1c40f", "#ffffff"]
                        
                        Repeater {
                            model: colorRow.colorPalette
                            delegate: Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: modelData
                                border.color: colorRow.selectedColor === modelData ? "#ffffff" : "#444444"
                                border.width: colorRow.selectedColor === modelData ? 2 : 1
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: colorRow.selectedColor = modelData
                                }
                            }
                        }
                    }
                }
            }
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
        workInput.text = timerBackend.workMinutes.toString();
        breakInput.text = timerBackend.shortBreakMinutes.toString();
        longBreakInput.text = timerBackend.longBreakMinutes.toString();
        aotToggle.checked = timerBackend.alwaysOnTop;
        soundToggle.checked = timerBackend.soundEnabled;
        flashToggle.checked = timerBackend.flashEnabled;
        colorRow.selectedColor = timerBackend.themeColor;
        dampingSlider.value = timerBackend.shaderDamping;
        
        speedSlider.value = timerBackend.shaderSpeed;
        meteorSlider.value = timerBackend.meteorFrequency;
        autoBreaksToggle.checked = timerBackend.autoStartBreaks;
        autoWorkToggle.checked = timerBackend.autoStartWork;
        lbiInput.text = timerBackend.longBreakInterval.toString();
        volumeSlider.value = timerBackend.alarmVolume;
        tickingToggle.checked = timerBackend.tickingEnabled;
        streamToggle.checked = timerBackend.streamEnabled;
        streamVolumeSlider.value = timerBackend.streamVolume;
        
        settingsPanel.opacity = 1.0;
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
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Space) {
            if (timerBackend.isRunning) {
                timerBackend.pause();
            } else {
                timerBackend.start();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_S) {
            if (settingsPanel.opacity > 0.0) {
                settingsPanel.opacity = 0.0;
            } else {
                openSettings();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            timerBackend.reset();
            event.accepted = true;
        } else if (event.key === Qt.Key_Z || event.key === Qt.Key_F) {
            zenMode = !zenMode;
            event.accepted = true;
        }
    }
}
