import QtQuick

Item {
    id: root
    width: parent ? parent.width : 300
    height: root.subtitle !== "" ? 32 : 20
    
    property string labelText: "Setting"
    property string subtitle: ""
    property bool checked: false
    property color themeColor: "#ffffff"
    property color themeContrastColor: "#000000"
    
    signal toggled()
    
    Column {
        anchors.left: parent.left
        anchors.right: toggleItem.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        
        Text {
            text: root.labelText
            color: "#aaaaaa"
            font.pixelSize: 13
        }
        
        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: "#555555"
            font.pixelSize: 10
            elide: Text.ElideRight
            width: parent.width
        }
    }
    
    Item {
        id: toggleItem
        width: 38
        height: 20
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: root.checked ? root.themeColor : "#2a2a2a"
            border.color: root.checked ? root.themeColor : "#3d3d3d"
            border.width: 1
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
