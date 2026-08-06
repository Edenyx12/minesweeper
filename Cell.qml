import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
Rectangle {
    id: cell

    property alias bomb_count: bomb_count
    property alias flagImage: flagImage
    property alias visualRect: visualRect
    property var root

    function setCellBombCount(count) {
        if (isBomb) { bomb_count.text = "B"; return; }
        if (count <= 0) { bomb_count.text = ""; return; }
        else if (count > 8) { bomb_count.text = 8; return; }
        bomb_count.text = count;
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    color: "transparent"
    antialiasing: true

    property real randomSeedX: 0.6 + Math.random()
    property real randomSeedY: 0.5 + Math.random()

    property int cellIndex: 0
    property bool opened: false; onOpenedChanged: cell.pulse = true
    property bool flaged: false
    property bool isBomb: false
    property bool triggered: {
        if (!root || root.currentHoverIndex === -1 || root.gameOver) return false;

        let hoverX = root.currentHoverIndex % root.field;
        let hoverY = Math.floor(root.currentHoverIndex / root.field);

        let cellX = cell.cellIndex % root.field;
        let cellY = Math.floor(cell.cellIndex / root.field);

        let isInside3x3 = (cellX >= hoverX - 1 && cellX <= hoverX + 1) &&
                          (cellY >= hoverY - 1 && cellY <= hoverY + 1);

        let isCenter = (cellX === hoverX && cellY === hoverY);

        return isInside3x3 && !isCenter;
    }

    property bool shake: false
    property bool pulse: false

    signal triggerEnable();
    signal triggerDisable();
    signal triggerOpen();
    signal triggerFlag();

    Rectangle {
        id: visualRect
        width: parent.width * 0.9
        height: parent.height * 0.9
        radius: width * 0.16
        anchors.centerIn: parent
        rotation: (anchors.horizontalCenterOffset + anchors.verticalCenterOffset) * 0.7

        antialiasing: true

        scale: {
            if (ma.containsMouse) return 1.1;
            else if (triggered)   return 0.9;
            else if (opened)      return 0.95;
            else                  return 1;
        }
        color: {
            if (root.isWin && isBomb) return "#195e2c"
            opened ? Qt.alpha("#0f0f0f", 0.5) : "#242126"
        }
        border.color: {
            let triggered_color = "#7477ab";
            let hovered_color = "#bb69ff";
            let default_color = "#3f3942";

            let bomb = "#ff4769";
            let winBomb = "#47ff6f";
            let pale_bomb = Qt.darker(bomb, 1.1);

            if (ma.containsPress) return "#adf3ff";
            if (ma.containsMouse) return hovered_color;
            if (root && root.gameOver && isBomb)
                return root.isWin ? winBomb : bomb;
            if (triggered && flaged) return pale_bomb;
            if (triggered) return triggered_color;

            return default_color;
        }
        border.width: {
            if (!opened && !ma.containsMouse && !triggered)
                return 2;

            ma.containsMouse ? 1.3 : 1.25
        }
        Behavior on border.color { ColorAnimation { duration: 150; easing: Easing.OutCubic } }
        Behavior on border.width { NumberAnimation { duration: 150; easing: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing: Easing.OutCubic } }

        Text {
            id: bomb_count
            text: "8"

            visible: cell.opened

            color: {
                let resultColor = "magenta";
                switch (text) {
                    case "1": resultColor = "#4A90E2"; break;
                    case "2": resultColor = "#5C9E6D"; break;
                    case "3": resultColor = "#E06D53"; break;
                    case "4": resultColor = "#8B6FB8"; break;
                    case "5": resultColor = "#D4A359"; break;
                    case "6": resultColor = "#5FA0A4"; break;
                    case "7": resultColor = "#A35C5C"; break;
                    case "8": resultColor = "#6C757D"; break;
                    case "B": resultColor = "transparent"; break;
                }
                Qt.lighter(resultColor, 1.2);
            }

            font.pixelSize: 28

            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
        }
        Image {
            id: flagImage
            width: 25
            height: 25
            anchors.centerIn: parent

            source: {
                if (root && root.gameOver) {
                    if (isBomb)
                        return root.isWin ? "data/mine.png" : "data/explosion.png";
                }
                return "data/flag.png";
            }

            visible: {
                if (flaged && !opened) return true;
                if (root && root.gameOver && isBomb) return true;

                return false;
            }
        }
    }
    ParallelAnimation {
        id: explodeAnimation
        running: cell.shake

        property int randomDelay: Math.floor(Math.random() * 250)

        SequentialAnimation {
            PauseAnimation { duration: explodeAnimation.randomDelay }
            SequentialAnimation {
                loops: 7
                PropertyAnimation { target: visualRect; property: "anchors.horizontalCenterOffset"; to: -4; duration: 20; easing: Easing.Linear }
                PropertyAnimation { target: visualRect; property: "anchors.horizontalCenterOffset"; to: 4; duration: 40; easing: Easing.Linear }
                PropertyAnimation { target: visualRect; property: "anchors.horizontalCenterOffset"; to: 0; duration: 20; easing: Easing.Linear }
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: explodeAnimation.randomDelay }
            PropertyAnimation { target: visualRect; property: "scale"; to: 1.1; duration: 150; easing: Easing.OutQuad }
            PropertyAnimation { target: visualRect; property: "scale"; to: 1.0; duration: 250; easing: Easing.InOutQuad }
        }

        SequentialAnimation {
            id: colorSeq
            PauseAnimation { duration: explodeAnimation.randomDelay }
            ColorAnimation { target: visualRect; property: "color"; to: "#7a1f2d"; duration: 120; easing: Easing.OutQuad }
            ColorAnimation { target: visualRect; property: "color"; to: Qt.alpha("#0f0f0f", 0.5); duration: 400; easing: Easing.InOutQuad }
        }

        onFinished: cell.shake = false
    }
    SequentialAnimation {
        id: pulseAnimation

        running: cell.pulse

        loops: 1

        PropertyAnimation {
            target: visualRect
            property: "scale"
            to: root.gameStarted ? 0.85 : 1.15
            duration: 100
            easing.type: Easing.InOutQuad
        }

        PropertyAnimation {
            target: visualRect
            property: "scale"
            to: 1.0
            duration: 400
            easing.type: Easing.InOutQuad
        }
        onFinished: cell.pulse = false
    }
    ParallelAnimation {
        id: floatAnimation
        running: root.isWin && isBomb
        loops: Animation.Infinite

        SequentialAnimation {
            NumberAnimation {
                target: visualRect; property: "anchors.verticalCenterOffset"
                from: 0; to: -4 * randomSeedY
                duration: 800 * randomSeedY
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: visualRect; property: "anchors.verticalCenterOffset"
                from: -4 * randomSeedY; to: 4 * randomSeedY
                duration: 800 * randomSeedY
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: visualRect; property: "anchors.verticalCenterOffset"
                from: 4 * randomSeedY; to: 0
                duration: 800 * randomSeedY
                easing.type: Easing.Linear
            }
        }

        SequentialAnimation {
            NumberAnimation {
                target: visualRect; property: "anchors.horizontalCenterOffset"
                from: 0; to: 3 * randomSeedX
                duration: 600 * randomSeedX
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: visualRect; property: "anchors.horizontalCenterOffset"
                from: 3 * randomSeedX; to: -3 * randomSeedX
                duration: 600 * randomSeedX
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: visualRect; property: "anchors.horizontalCenterOffset"
                from: -3 * randomSeedX; to: 0
                duration: 600 * randomSeedX
                easing.type: Easing.InOutSine
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        z: 2

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        pressAndHoldInterval: 250

        onEntered: cell.triggerEnable();
        onExited: cell.triggerDisable();
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                cell.triggerFlag();
            }
            else if (mouse.button === Qt.LeftButton) {
                cell.triggerOpen();
            }
        }
        onPressAndHold: {
            cell.triggerFlag();
        }
    }
}
