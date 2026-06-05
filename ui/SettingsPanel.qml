import QtQuick
import QtQuick.Controls

    Rectangle {
        id: root
        property color themeColor: "#ffffff"
        property color themeContrastColor: "#000000"
        property string activePreset: "Pomodoro"
        property string timerMode: "countdown"
        
        signal saveRequested(var settings)
        signal updateKeybindsRequested(string p1, string p2, string p3, string p4, string p5, string p6)
        signal closed()

        function open(settings) {
            root.activePreset = settings.activePreset || "Pomodoro";
            root.timerMode = settings.timerMode || "countdown";
            
            var presetIdx = presetComboBox.indexOfValue(root.activePreset);
            if (presetIdx >= 0) {
                presetComboBox.currentIndex = presetIdx;
            }

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
            compactWidthInput.text = settings.compactWidthThreshold.toString();
            compactHeightInput.text = settings.compactHeightThreshold.toString();
            clockScaleSlider.value = settings.clockScale;
            
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
                            streamVolume: streamVolumeSlider.value,
                            compactWidthThreshold: parseInt(compactWidthInput.text) || 400,
                            compactHeightThreshold: parseInt(compactHeightInput.text) || 250,
                            clockScale: clockScaleSlider.value,
                            activePreset: root.activePreset,
                            timerMode: root.timerMode
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

                Text {
                    id: midSessionWarning
                    width: parent.width
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    color: "#ff4d4d"
                    font.pixelSize: 11
                    font.bold: true
                    text: "⚠️ SAVING WILL RESET THE ACTIVE FOCUS SESSION"
                    visible: timerBackend.isRunning || timerBackend.currentState !== "work" || (timerBackend.timerMode === "flowtime" ? timerBackend.progress > 0.0 : (timerBackend.progress > 0.0 && timerBackend.progress < 1.0))
                }

                // Preset Dropdown Row
                Item {
                    width: parent.width
                    height: 26
                    
                    Text {
                        text: "Focus Preset"
                        color: "#888888"
                        font.pixelSize: 13
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    ComboBox {
                        id: presetComboBox
                        anchors.right: parent.right
                        width: 140
                        height: 26
                        model: timerBackend.presetsList
                        
                        background: Rectangle {
                            color: "#181818"
                            border.color: presetComboBox.activeFocus ? root.themeColor : "#333333"
                            border.width: 1
                            radius: 3
                        }
                        
                        contentItem: Text {
                            leftPadding: 8
                            rightPadding: presetComboBox.indicator.width + presetComboBox.spacing
                            text: presetComboBox.displayText
                            font.pixelSize: 12
                            color: "#ffffff"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        
                        delegate: ItemDelegate {
                            width: presetComboBox.width
                            height: 26
                            contentItem: Text {
                                text: modelData
                                color: highlighted ? root.themeContrastColor : "#aaaaaa"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: highlighted ? root.themeColor : "#181818"
                            }
                        }
                        
                        popup: Popup {
                            y: presetComboBox.height
                            width: presetComboBox.width
                            implicitHeight: Math.min(200, contentItem.implicitHeight)
                            padding: 1
                            
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: presetComboBox.popup.visible ? presetComboBox.delegateModel : null
                                currentIndex: presetComboBox.highlightedIndex
                                ScrollIndicator.vertical: ScrollIndicator { }
                            }
                            
                            background: Rectangle {
                                color: "#181818"
                                border.color: "#333333"
                                radius: 3
                            }
                        }
                        
                        onActivated: (index) => {
                            var name = presetComboBox.currentText;
                            root.activePreset = name;
                            var details = timerBackend.getPresetDetails(name);
                            if (details && details.mode) {
                                root.timerMode = details.mode;
                                if (details.mode === "countdown") {
                                    workInput.text = details.work_minutes.toString();
                                    breakInput.text = details.short_break_minutes.toString();
                                    longBreakInput.text = details.long_break_minutes.toString();
                                    lbiInput.text = details.long_break_interval.toString();
                                }
                            }
                        }
                    }
                }

                // 1. Durations Group
                Column {
                    width: parent.width
                    spacing: 12
                    
                    SettingNumberInput { id: workInput; labelText: "Work Duration (min)"; themeColor: root.themeColor; enabled: root.timerMode !== "flowtime"; opacity: enabled ? 1.0 : 0.4 }
                    SettingNumberInput { id: breakInput; labelText: "Short Break (min)"; themeColor: root.themeColor; enabled: root.timerMode !== "flowtime"; opacity: enabled ? 1.0 : 0.4 }
                    SettingNumberInput { id: longBreakInput; labelText: "Long Break (min)"; themeColor: root.themeColor; enabled: root.timerMode !== "flowtime"; opacity: enabled ? 1.0 : 0.4 }
                    SettingNumberInput { id: lbiInput; labelText: "Long Break Interval (cycles)"; themeColor: root.themeColor; topValidator: 99; enabled: root.timerMode !== "flowtime"; opacity: enabled ? 1.0 : 0.4 }
                }

                // Divider
                Rectangle { width: parent.width; height: 1; color: "#1b1b1b" }

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
                                width: 55; height: 26
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
                                width: 55; height: 26
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

                    SettingToggle { id: aotToggle; labelText: "Always on Top"; themeColor: root.themeColor; themeContrastColor: root.themeContrastColor }
                    SettingToggle { id: soundToggle; labelText: "Audible Alarm"; themeColor: root.themeColor; themeContrastColor: root.themeContrastColor }
                    SettingToggle { id: flashToggle; labelText: "Screen Flash on End"; themeColor: root.themeColor; themeContrastColor: root.themeContrastColor }
                    SettingToggle { id: autoBreaksToggle; labelText: "Auto-Start Breaks"; themeColor: root.themeColor; themeContrastColor: root.themeContrastColor }
                    SettingToggle { id: autoWorkToggle; labelText: "Auto-Start Work"; themeColor: root.themeColor; themeContrastColor: root.themeContrastColor }
                    SettingToggle { id: tickingToggle; labelText: "Soft Ticking Sound"; themeColor: root.themeColor; themeContrastColor: root.themeContrastColor }
                }

                // Divider
                Rectangle { width: parent.width; height: 1; color: "#1b1b1b" }

                // 3. Audio Volume Slider
                SettingSlider { 
                    id: volumeSlider; 
                    labelText: "Alarm Volume (" + (value * 100).toFixed(0) + "%)"; 
                    themeColor: root.themeColor; 
                    from: 0.0; to: 1.0; stepSize: 0.05 
                }

                SettingToggle { id: streamToggle; labelText: "Stream late.sh"; themeColor: root.themeColor; themeContrastColor: root.themeContrastColor }

                SettingSlider { 
                    id: streamVolumeSlider; 
                    labelText: "Stream Volume (" + (value * 100).toFixed(0) + "%)"; 
                    themeColor: root.themeColor; 
                    from: 0.0; to: 1.0; stepSize: 0.05 
                }

                // 4. Shader Sliders
                SettingSlider { 
                    id: dampingSlider; 
                    labelText: "Shader Trail Delay (" + value.toFixed(2) + ")"; 
                    themeColor: root.themeColor; 
                    from: 0.01; to: 0.20; stepSize: 0.01 
                }

                SettingSlider { 
                    id: speedSlider; 
                    labelText: "Star Drift Speed (" + (value * 1000).toFixed(0) + ")"; 
                    themeColor: root.themeColor; 
                    from: 0.00; to: 0.05; stepSize: 0.005 
                }

                SettingSlider { 
                    id: meteorSlider; 
                    labelText: "Shooting Stars (" + (value * 100).toFixed(0) + "%)"; 
                    themeColor: root.themeColor; 
                    from: 0.0; to: 1.0; stepSize: 0.1 
                }

                // Divider
                Rectangle { width: parent.width; height: 1; color: "#1b1b1b" }

                // 5. Keybindings Group
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
                Rectangle { width: parent.width; height: 1; color: "#1b1b1b" }

                // 6. Theme Colors row
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
                                width: 24; height: 24; radius: 12
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

                // Divider
                Rectangle { width: parent.width; height: 1; color: "#1b1b1b" }

                // 7. Window Layout Group
                Column {
                    width: parent.width
                    spacing: 12
                    
                    SettingSlider { 
                        id: clockScaleSlider; 
                        labelText: "Clock Scale (" + value.toFixed(2) + "x)"; 
                        themeColor: root.themeColor; 
                        from: 0.5; to: 2.5; stepSize: 0.05 
                    }
                    
                    SettingNumberInput { id: compactWidthInput; labelText: "Compact Width Threshold (px)"; themeColor: root.themeColor; topValidator: 4000 }
                    SettingNumberInput { id: compactHeightInput; labelText: "Compact Height Threshold (px)"; themeColor: root.themeColor; topValidator: 4000 }
                }
            }
        }
    }
