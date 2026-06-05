import QtQuick

Item {
    id: root
    width: parent ? parent.width : 300
    height: 26
    
    property string labelText: "Input"
    property string text: ""
    property int bottomValidator: 1
    property int topValidator: 999
    property color themeColor: "#ffffff"
    
    Text {
        text: root.labelText
        color: "#888888"
        font.pixelSize: 13
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }
    
    Rectangle {
        width: 70
        height: 26
        color: "#181818"
        border.color: textInput.activeFocus ? root.themeColor : "#333333"
        radius: 3
        anchors.right: parent.right
        
        TextInput {
            id: textInput
            anchors.fill: parent
            anchors.margins: 3
            color: "#ffffff"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            validator: IntValidator { bottom: root.bottomValidator; top: root.topValidator }
            text: root.text
            onTextChanged: {
                root.text = textInput.text;
            }
        }
    }
}
