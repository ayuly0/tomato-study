import QtQuick

Row {
    id: root
    spacing: 8

    // These properties should be set from outside
    property string timeString: "00:00"
    property bool isRunning: false
    property int referenceSize: 300 // Math.min(root.width, root.height) passed from parent

    readonly property var parts: timeString.indexOf(":") !== -1 ? timeString.split(":") : ["00", "00"]
    readonly property string minStr: parts.length > 0 ? parts[0] : "00"
    readonly property string secStr: parts.length > 1 ? parts[1] : "00"

    // Optional hundreds card for Flowtime sessions exceeding 99 minutes
    FlipDigit {
        id: minHundredsCard
        width: root.referenceSize * 0.16
        height: width * 1.4
        visible: root.minStr.length > 2
        value: root.minStr.length > 2 ? root.minStr.charAt(0) : "0"
    }

    FlipDigit {
        id: minTensCard
        width: root.referenceSize * 0.16
        height: width * 1.4
        value: root.minStr.length > 2 ? root.minStr.charAt(1) : (root.minStr.length > 1 ? root.minStr.charAt(0) : "0")
    }
    
    FlipDigit {
        id: minOnesCard
        width: minTensCard.width
        height: minTensCard.height
        value: root.minStr.length > 0 ? root.minStr.charAt(root.minStr.length - 1) : "0"
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
        value: root.secStr.length > 0 ? root.secStr.charAt(0) : "0"
    }
    
    FlipDigit {
        id: secOnesCard
        width: minTensCard.width
        height: minTensCard.height
        value: root.secStr.length > 1 ? root.secStr.charAt(1) : (root.secStr.length > 0 ? root.secStr.charAt(0) : "0")
    }
}

