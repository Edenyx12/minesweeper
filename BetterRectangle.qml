import QtQuick


Item {
    id: global

    // ------ Local Alias
    property alias localWidth: local.width
    property alias localHeight: local.height
    property alias localScale: local.scale
    property alias localOpacity: local.opacity
    property alias localVisible: local.visible
    property alias localAnchors: local.anchors

    // Local
    Rectangle {
        id: local
        anchors.centerIn: parent
    }
}
