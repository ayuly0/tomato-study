import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: parent ? parent.width : 300
    height: 26
    
    property string labelText: "Slider"
    property real value: 0.0
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.05
    property color themeColor: "#ffffff"
    

    
    Text {
        text: root.labelText
        color: "#888888"
        font.pixelSize: 13
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }
    
    Slider {
        id: slider
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        width: 120
        anchors.right: parent.right
        
        onMoved: {
            root.value = slider.value;
        }
        
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 120
            implicitHeight: 4
            width: slider.availableWidth
            height: implicitHeight
            radius: 2
            color: "#333333"
            
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: root.themeColor
                radius: 2
            }
        }
        
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 14
            implicitHeight: 14
            radius: 7
            color: "#ffffff"
            border.color: root.themeColor
            border.width: 1
        }
    }
}
