import QtQuick

Item {
    id: card
    property string value: "0"
    property string prevValue: "0"
    property bool completed: false

    Component.onCompleted: {
        prevValue = value;
        completed = true;
    }

    onValueChanged: {
        if (completed) {
            flipAnimation.restart();
        } else {
            prevValue = value;
        }
    }

    // Background card showing the NEXT value
    Rectangle {
        id: nextCard
        anchors.fill: parent
        color: "#161616"
        radius: 8
        border.color: "#2c2c2c"
        border.width: 1
        
        // Top Half
        Item {
            width: parent.width
            height: parent.height / 2
            clip: true
            
            Text {
                width: parent.width
                height: card.height
                y: 0
                text: card.value
                color: "#ffffff"
                font.pixelSize: card.height * 0.75
                font.bold: true
                font.family: "Courier New"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        
        // Bottom Half
        Item {
            width: parent.width
            height: parent.height / 2
            y: parent.height / 2
            clip: true
            
            Text {
                width: parent.width
                height: card.height
                y: -card.height / 2
                text: card.value
                color: "#ffffff"
                font.pixelSize: card.height * 0.75
                font.bold: true
                font.family: "Courier New"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // The top folding flap (animates from 0 to 90 degrees flat)
    Rectangle {
        id: topFlap
        width: parent.width
        height: parent.height / 2
        color: "#161616"
        radius: 8
        border.color: "#2c2c2c"
        border.width: 1
        clip: true
        
        Text {
            width: parent.width
            height: card.height
            y: 0
            text: card.prevValue
            color: "#ffffff"
            font.pixelSize: card.height * 0.75
            font.bold: true
            font.family: "Courier New"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        
        transform: Rotation {
            id: topRotation
            axis.x: 1; axis.y: 0; axis.z: 0
            origin.x: topFlap.width / 2
            origin.y: topFlap.height
            angle: 0
        }
    }

    // The bottom folding flap (animates from 90 degrees flat to 0 degrees standard)
    Rectangle {
        id: bottomFlap
        width: parent.width
        height: parent.height / 2
        y: parent.height / 2
        color: "#161616"
        radius: 8
        border.color: "#2c2c2c"
        border.width: 1
        clip: true
        visible: topRotation.angle >= 90
        
        Text {
            width: parent.width
            height: card.height
            y: -card.height / 2
            text: card.value
            color: "#ffffff"
            font.pixelSize: card.height * 0.75
            font.bold: true
            font.family: "Courier New"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        
        transform: Rotation {
            id: bottomRotation
            axis.x: 1; axis.y: 0; axis.z: 0
            origin.x: bottomFlap.width / 2
            origin.y: 0
            angle: 90
        }
    }

    // Horizontal split line in the middle
    Rectangle {
        width: parent.width
        height: 2
        y: parent.height / 2 - 1
        color: "#000000"
        opacity: 0.7
    }

    // Coordinated Flip transitions
    SequentialAnimation {
        id: flipAnimation
        
        // Fold old top half down to 90 degrees
        NumberAnimation {
            target: topRotation
            property: "angle"
            from: 0
            to: 90
            duration: 150
            easing.type: Easing.InQuad
        }
        
        // Fold new bottom half down from 90 to 0 degrees
        NumberAnimation {
            target: bottomRotation
            property: "angle"
            from: 90
            to: 0
            duration: 150
            easing.type: Easing.OutQuad
        }
        
        ScriptAction {
            script: {
                topRotation.angle = 0;
                bottomRotation.angle = 90;
                card.prevValue = card.value;
            }
        }
    }
}
