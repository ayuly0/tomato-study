import QtQuick

Row {
    id: root
    spacing: 2

    // Properties should be set from outside
    property string timeString: "00:00"
    property color themeColor: "#ffffff"
    property int referenceSize: 300 // Math.min(parent.width, parent.height) from parent

    Text {
        text: root.timeString
        color: "#ffffff"
        font.pixelSize: root.referenceSize * 0.30
        font.bold: true
        font.family: "Inter"
        font.weight: Font.Black
        style: Text.Outline
        styleColor: root.themeColor
    }
}
