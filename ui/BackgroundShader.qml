import QtQuick

Item {
    id: root
    anchors.fill: parent

    // Configuration properties
    property real damping: 0.1
    property color themeColor: "#ffffff"
    property real shaderSpeed: 0.01
    property real meteorFrequency: 0.0

    // State properties
    property bool isPaused: false
    
    // Inputs for interaction
    property real targetX: 0.5
    property real targetY: 0.5

    ShaderEffect {
        id: shaderEffect
        anchors.fill: parent
        
        property real currentX: 0.5
        property real currentY: 0.5
        
        property point mouse: Qt.point(0.5, 0.5)
        property real time: 0.0
        property color themeColor: root.themeColor
        property real aspect: width / height
        property real shaderSpeed: root.shaderSpeed
        property real meteorFrequency: root.meteorFrequency
        
        visible: opacity > 0.0
        opacity: root.isPaused ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        fragmentShader: "shader.frag.qsb"
    }

    Timer {
        id: shaderTimer
        interval: 16
        running: !root.isPaused && root.visible && root.opacity > 0.0
        repeat: true
        onTriggered: {
            shaderEffect.currentX += (root.targetX - shaderEffect.currentX) * root.damping;
            shaderEffect.currentY += (root.targetY - shaderEffect.currentY) * root.damping;
            shaderEffect.mouse = Qt.point(shaderEffect.currentX, shaderEffect.currentY);
            shaderEffect.time += 0.016;
        }
    }
}
