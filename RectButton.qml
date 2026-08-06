import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: button

    // ------ Controls Settings
    property bool scaleAnim: true
    property bool opacityAnim: true
    property bool colorAnim: true
    property bool borderWidthAnim: true
    property bool borderColorAnim: true

    // ------ Controls Fields
    property var scaleControls: [0.8, 0.9, 1]
    property var opacityControls: [0.5, 0.75, 1]
    property var colorControls: ["#17151a", "#1b191f", "#29252e"]
    property var borderWidthControls: [1, 2, 3]
    property var borderColorControls: ["#4d4659", "#685f78", "#9285a8"]

    // ------ Icon (optional)
    property alias iconSource: icon.source
    property alias iconWidth: icon.width
    property alias iconHeight: icon.height

    // ------ Text (optional)
    property alias textContent: text.text
    property alias textWidth: text.width
    property alias textHeight: text.height
    property alias textColor: text.color
    property alias textFontSize: text.font.pixelSize

    // ------ Other
    signal touched()

    // Main Logic
    color: state(...colorControls, colorAnim)
    opacity: state(...opacityControls, opacityAnim)
    scale: state(...scaleControls, scaleAnim)
    border.width: state(...borderWidthControls, borderWidthAnim)
    border.color: state(...borderColorControls, borderColorAnim)

    // Functions
    function state(base, hover, click, active) {
        if (active === false) return base;
        if (ma.containsPress) return click;
        if (ma.containsMouse) return hover;
        return base;
    }

    // Behaviors
    Behavior on color { ColorAnimation { duration: 100; easing: Easing.OutQuad } }
    Behavior on opacity { NumberAnimation { duration: 100; easing: Easing.OutQuad } }
    Behavior on scale { NumberAnimation { duration: 100; easing: Easing.OutQuad } }
    Behavior on border.color { ColorAnimation { duration: 100; easing: Easing.OutQuad } }
    Behavior on border.width { NumberAnimation { duration: 100; easing: Easing.OutQuad } }
    // Visual
    Image {
        id: icon
        sourceSize.width: width
        sourceSize.height: height
        anchors.centerIn: parent
    }
    Text { id: text; anchors.centerIn: parent }
    // Controls
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: touched()
    }
}
