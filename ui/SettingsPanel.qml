import QtQuick
import QtQuick.Controls

    Rectangle {
        id: root
    property color themeColor: "#ffffff"
    property color themeContrastColor: "#000000"
    
    signal saveRequested(var settings)
    signal updateKeybindsRequested(string p1, string p2, string p3, string p4, string p5, string p6)
    signal closed()

    function open(settings) {
        workInput.text = settings.workMinutes.toString();
        breakInput.text = settings.shortBreakMinutes.toString();
        longBreakInput.text = settings.longBreakMinutes.toString();
        aotToggle.checked = settings.alwaysOnTop;
        soundToggle.checked = settings.soundEnabled;
        flashToggle.checked = settings.flashEnabled;
        colorRow.selectedColor = settings.themeColor;
        themeRow.selectedTheme = settings.clockTheme;
        dampingSlider.value = settings.shaderDamping;
        speedSlider.value = settings.shaderSpeed;
        meteorSlider.value = settings.meteorFrequency;
        autoBreaksToggle.checked = settings.autoStartBreaks;
        autoWorkToggle.checked = settings.autoStartWork;
        lbiInput.text = settings.longBreakInterval.toString();
        volumeSlider.value = settings.alarmVolume;
        tickingToggle.checked = settings.tickingEnabled;
        streamToggle.checked = settings.streamEnabled;
        streamVolumeSlider.value = settings.streamVolume;
        
        playPauseKB.currentKey = settings.keybindPlayPause;
        resetKB.currentKey = settings.keybindReset;
        settingsKB.currentKey = settings.keybindSettings;
        zenKB.currentKey = settings.keybindZenMode;
        streamKB.currentKey = settings.keybindStream;
        muteKB.currentKey = settings.keybindMute;
        
        root.opacity = 1.0;
    }
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
                    onClicked: root.opacity = 0.0
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
                        
                        var s = {
                            workMinutes: w,
                            shortBreakMinutes: b,
                            longBreakMinutes: lb,
                            alwaysOnTop: aotToggle.checked,
                            soundEnabled: soundToggle.checked,
                            flashEnabled: flashToggle.checked,
                            themeColor: colorRow.selectedColor,
                            shaderDamping: dampingSlider.value,
                            shaderSpeed: speedSlider.value,
                            meteorFrequency: meteorSlider.value,
                            clockTheme: themeRow.selectedTheme,
                            autoStartBreaks: autoBreaksToggle.checked,
                            autoStartWork: autoWorkToggle.checked,
                            longBreakInterval: lbi,
                            alarmVolume: volumeSlider.value,
                            tickingEnabled: tickingToggle.checked,
                            streamEnabled: streamToggle.checked,
                            streamVolume: streamVolumeSlider.value
                        };
                        root.saveRequested(s);
                        root.opacity = 0.0;
                        root.closed();
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
                            border.color: workInput.activeFocus ? root.themeColor : "#333333"
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
                            border.color: breakInput.activeFocus ? root.themeColor : "#333333"
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
                            border.color: longBreakInput.activeFocus ? root.themeColor : "#333333"
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
                            border.color: lbiInput.activeFocus ? root.themeColor : "#333333"
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
                    
                    // Clock Theme Selector
                    Item {
                        width: parent.width
                        height: 26
                        
                        Text {
                            text: "Clock Theme"
                            color: "#888888"
                            font.pixelSize: 13
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Row {
                            id: themeRow
                            anchors.right: parent.right
                            spacing: 8
                            property string selectedTheme: "digital"
                            
                            Rectangle {
                                width: 55
                                height: 26
                                color: themeRow.selectedTheme === "flip" ? root.themeColor : "#181818"
                                border.color: "#333333"
                                radius: 3
                                Text {
                                    text: "Flip"
                                    color: themeRow.selectedTheme === "flip" ? root.themeContrastColor : "#888888"
                                    anchors.centerIn: parent
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: themeRow.selectedTheme = "flip"
                                }
                            }
                            
                            Rectangle {
                                width: 55
                                height: 26
                                color: themeRow.selectedTheme === "digital" ? root.themeColor : "#181818"
                                border.color: "#333333"
                                radius: 3
                                Text {
                                    text: "Digital"
                                    color: themeRow.selectedTheme === "digital" ? root.themeContrastColor : "#888888"
                                    anchors.centerIn: parent
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: themeRow.selectedTheme = "digital"
                                }
                            }
                        }
                    }

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
                                color: aotToggle.checked ? root.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: aotToggle.checked ? root.themeContrastColor : "#ffffff"
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
                                color: soundToggle.checked ? root.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: soundToggle.checked ? root.themeContrastColor : "#ffffff"
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
                                color: flashToggle.checked ? root.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: flashToggle.checked ? root.themeContrastColor : "#ffffff"
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
                                color: autoBreaksToggle.checked ? root.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: autoBreaksToggle.checked ? root.themeContrastColor : "#ffffff"
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
                                color: autoWorkToggle.checked ? root.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: autoWorkToggle.checked ? root.themeContrastColor : "#ffffff"
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
                                color: tickingToggle.checked ? root.themeColor : "#333333"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: tickingToggle.checked ? root.themeContrastColor : "#ffffff"
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
                                color: root.themeColor
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
                            border.color: root.themeColor
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
                            color: streamToggle.checked ? root.themeColor : "#333333"
                             Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: streamToggle.checked ? root.themeContrastColor : "#ffffff"
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
                                color: root.themeColor
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
                            border.color: root.themeColor
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
                                color: root.themeColor
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
                            border.color: root.themeColor
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
                                color: root.themeColor
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
                            border.color: root.themeColor
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
                                color: root.themeColor
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
                            border.color: root.themeColor
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

                // 3. Keybindings Group
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Keybindings"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    KeybindItem {
                        id: playPauseKB
                        labelText: "Play / Pause"
                        themeColor: root.themeColor
                        onKeySelected: (key) => root.updateKeybindsRequested(key, resetKB.currentKey, settingsKB.currentKey, zenKB.currentKey, streamKB.currentKey, muteKB.currentKey)
                    }
                    KeybindItem {
                        id: resetKB
                        labelText: "Reset Timer"
                        themeColor: root.themeColor
                        onKeySelected: (key) => root.updateKeybindsRequested(playPauseKB.currentKey, key, settingsKB.currentKey, zenKB.currentKey, streamKB.currentKey, muteKB.currentKey)
                    }
                    KeybindItem {
                        id: settingsKB
                        labelText: "Toggle Settings"
                        themeColor: root.themeColor
                        onKeySelected: (key) => root.updateKeybindsRequested(playPauseKB.currentKey, resetKB.currentKey, key, zenKB.currentKey, streamKB.currentKey, muteKB.currentKey)
                    }
                    KeybindItem {
                        id: zenKB
                        labelText: "Zen Mode"
                        themeColor: root.themeColor
                        onKeySelected: (key) => root.updateKeybindsRequested(playPauseKB.currentKey, resetKB.currentKey, settingsKB.currentKey, key, streamKB.currentKey, muteKB.currentKey)
                    }
                    KeybindItem {
                        id: streamKB
                        labelText: "Toggle Stream"
                        themeColor: root.themeColor
                        onKeySelected: (key) => root.updateKeybindsRequested(playPauseKB.currentKey, resetKB.currentKey, settingsKB.currentKey, zenKB.currentKey, key, muteKB.currentKey)
                    }
                    KeybindItem {
                        id: muteKB
                        labelText: "Mute Alarm"
                        themeColor: root.themeColor
                        onKeySelected: (key) => root.updateKeybindsRequested(playPauseKB.currentKey, resetKB.currentKey, settingsKB.currentKey, zenKB.currentKey, streamKB.currentKey, key)
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
                        property string selectedColor: "#ffffff"
                        
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
