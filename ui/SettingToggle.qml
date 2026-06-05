import QtQuick

Item {
    id: root
    width: parent ? parent.width : 300
    height: 20
    
    property string labelText: "Setting"
    property bool checked: false
    property color themeColor: "#ffffff"
    property color themeContrastColor: "#000000"
    
    signal toggled()
    
    Text {
        text: root.labelText
        color: "#888888"
        font.pixelSize: 13
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }
    
    Item {
        width: 38
        height: 20
        anchors.right: parent.right
        
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: root.checked ? root.themeColor : "#333333"
            Behavior on color { ColorAnimation { duration: 150 } }
            
            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: root.checked ? root.themeContrastColor : "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? 20 : 4
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.checked = !root.checked;
                root.toggled();
            }
        }
    }
}
