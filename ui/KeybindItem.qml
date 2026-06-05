import QtQuick

Item {
    id: root
    width: parent.width
    height: 26
    
    property string labelText: "Action"
    property string currentKey: ""
    property color themeColor: "#ffffff"
    
    property bool isRecording: false

    signal keySelected(string key)

    Text {
        text: root.labelText
        color: "#888888"
        font.pixelSize: 13
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }
    
    Rectangle {
        id: btn
        width: 80
        height: 24
        radius: 3
        color: root.isRecording ? "#222222" : "#111111"
        border.color: root.isRecording ? root.themeColor : "#444444"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
            text: root.isRecording ? "Press key..." : root.currentKey
            color: root.isRecording ? root.themeColor : "#ffffff"
            font.pixelSize: 11
            font.bold: true
            anchors.centerIn: parent
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!root.isRecording) {
                    root.isRecording = true
                    btn.forceActiveFocus()
                } else {
                    root.isRecording = false
                }
            }
        }
        
        Keys.onPressed: (event) => {
            if (root.isRecording) {
                var modifiers = "";
                if (event.modifiers & Qt.ControlModifier) modifiers += "Ctrl+";
                if (event.modifiers & Qt.AltModifier) modifiers += "Alt+";
                if (event.modifiers & Qt.ShiftModifier) modifiers += "Shift+";
                if (event.modifiers & Qt.MetaModifier) modifiers += "Meta+";
                
                var keyStr = "";
                if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                    keyStr = String.fromCharCode(event.key);
                } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                    keyStr = String.fromCharCode(event.key);
                } else if (event.key === Qt.Key_Space) {
                    keyStr = "Space";
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    keyStr = "Return";
                } else if (event.key === Qt.Key_Escape) {
                    root.isRecording = false; // Cancel recording
                    event.accepted = true;
                    return;
                } else if (event.text !== "") {
                    keyStr = event.text.toUpperCase();
                } else {
                    event.accepted = true;
                    return;
                }
                
                root.keySelected(modifiers + keyStr);
                root.isRecording = false;
                event.accepted = true;
            }
        }
        
        onFocusChanged: {
            if (!focus && isRecording) {
                isRecording = false;
            }
        }
    }
}
