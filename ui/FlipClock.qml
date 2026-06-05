import QtQuick

Row {
    id: root
    spacing: 8

    // These properties should be set from outside
    property string timeString: "00:00"
    property bool isRunning: false
    property int referenceSize: 300 // Math.min(root.width, root.height) passed from parent

    FlipDigit {
        id: minTensCard
        width: root.referenceSize * 0.16
        height: width * 1.4
        value: root.timeString.charAt(0)
    }
    
    FlipDigit {
        id: minOnesCard
        width: minTensCard.width
        height: minTensCard.height
        value: root.timeString.charAt(1)
    }
    
    Text {
        id: colonText
        text: ":"
        color: "#ffffff"
        font.pixelSize: minTensCard.height * 0.65
        font.bold: true
        font.family: "Courier New"
        anchors.verticalCenter: parent.verticalCenter
    }

    FlipDigit {
        id: secTensCard
        width: minTensCard.width
        height: minTensCard.height
        value: root.timeString.charAt(3)
    }
    
    FlipDigit {
        id: secOnesCard
        width: minTensCard.width
        height: minTensCard.height
        value: root.timeString.charAt(4)
    }
}
