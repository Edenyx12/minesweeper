import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic


ApplicationWindow {
    id: window
    width: 540
    height: 960
    minimumWidth: 200
    minimumHeight: 250
    visible: true
    title: qsTr("Minesweeper")

    property real bombCount: 10
    property var bombCellsList: []
    property var flaggedCellsList: []
    property var openQueue: []
    property bool gameOver: false
    property bool gameStarted: true
    property bool isWin: false;
    property int currentHoverIndex: -1
    property real field: 8

    function explodeAllBombs() {
        gameOver = true;
        bombCellsList.forEach(function(bombCell) {
            bombCell.opened = true;
            bombCell.shake = true;
        });
        // game over logic
        winOrLose.text = "Lose!";
        winOrLose.color = "red";
        isWin = false;
    }
    function checkWinCondition() {
        if (gameOver) return;

        let closedCount = 0;
        let fieldSize = field * field;
        for (let i = 0; i < fieldSize; i++) {
            let currentCell = fieldRepeater.itemAt(i);
            if (currentCell && !currentCell.opened) closedCount++;
        }

        if (closedCount === bombCount) {
            gameOver = true;
            // win logic
            winOrLose.text = "Win!";
            winOrLose.color = "green";
            isWin = true;
            flagCount.text = bombCount + "/" + bombCount;

            bombCellsList.forEach(function(bombCell) {
                bombCell.flaged = true;
            });
        }
    }

    function toggleFlag(cell) {
        if (cell.opened || gameOver) return;

        if (gameStarted) generateField();

        cell.flaged = !cell.flaged;

        let list = flaggedCellsList;
        if (cell.flaged) {
            list.push(cell);
        }
        else {
            let index = list.indexOf(cell);
            if (index > -1) {
                list.splice(index, 1);
            }
        }
        flaggedCellsList = list;

        flagCount.text = flaggedCellsList.length + "/" + bombCount;
        checkWinCondition();
    }
    function setHoverZone(cell, active) {
        if (active && cell) {
            currentHoverIndex = cell.cellIndex;
        }
        else {
            if (cell && currentHoverIndex === cell.cellIndex) {
                currentHoverIndex = -1;
            }
        }
    }

    function setOpenCell(cell) {
        if (gameOver || !cell || cell.opened || cell.flaged) return;

        if (gameStarted) generateField(cell);

        if (cell.isBomb) {
            cascadeTimer.stop();
            explodeAllBombs();
            return;
        }

        let list = openQueue;
        list.push(cell);
        openQueue = list;

        if (!cascadeTimer.running) cascadeTimer.start();
    }

    function getCell(x, y) {
        if (x < 0 || x >= field || y < 0 || y >= field) return null;
        let index = y * field + x;
        return fieldRepeater.itemAt(index);
    }
    function cellToCoord(cell) {
        if (!cell) return { x: -1, y: -1 };
        let idx = cell.cellIndex;
        let cellX = idx % field;
        let cellY = Math.floor(idx / field);
        return { x: cellX, y: cellY };
    }
    function getNeighborsCoords(x, y) {
        return [
            { x: x - 1, y: y + 1 },
            { x: x,     y: y + 1 },
            { x: x + 1, y: y + 1 },
            { x: x - 1, y: y     },
            { x: x + 1, y: y     },
            { x: x - 1, y: y - 1 },
            { x: x,     y: y - 1 },
            { x: x + 1, y: y - 1 }
        ];
    }
    function getCrossNeighborsCoords(x, y) {
        let neighbors = [];
        let offsets = [{dx:1, dy:0}, {dx:-1, dy:0}, {dx:0, dy:1}, {dx:0, dy:-1}];

        offsets.forEach(function(offset) {
            let nx = x + offset.dx;
            let ny = y + offset.dy;
            if (nx >= 0 && nx < field && ny >= 0 && ny < field)
                neighbors.push({ x: nx, y: ny });

        });
        return neighbors;
    }
    function clearField() {
        let fieldSize = field * field;
        if (fieldRepeater.count !== fieldSize && fieldRepeater.count !== 0) return;

        gameOver = false;
        isWin = false;
        bombCellsList = [];
        flaggedCellsList = [];
        flagCount.text = flaggedCellsList.length + "/" + bombCount;
        winOrLose.text = ""
        cascadeTimer.stop();
        openQueue = [];

        fieldRepeater.model = 0;
        fieldRepeater.model = fieldSize;

        let allIndices = Array.from({length: fieldSize}, (_, idx) => idx);

        allIndices.forEach(function(idx) {
            let currentCell = fieldRepeater.itemAt(idx);
            if (currentCell) {
                currentCell.isBomb = false;
                currentCell.opened = false;
                currentCell.flaged = false;
                currentCell.shake = false;
                currentCell.pulse = true;
                currentCell.setCellBombCount(0);
            }
        });
    }

    function generateField(firstClickCell) {
        let fieldSize = field * field;
        if (fieldRepeater.count !== fieldSize) return;
        gameStarted = false;

        for (let i = 0; i < fieldSize; i++) {
            let c = fieldRepeater.itemAt(i);
            if (c) {
                c.isBomb = false;
                c.setCellBombCount(0);
            }
        }

        let forbiddenIndices = [];

        if (firstClickCell) {
            let clickIdx = firstClickCell.cellIndex;
            let clickCoords = cellToCoord(firstClickCell);
            let clickNeighbors = getNeighborsCoords(clickCoords.x, clickCoords.y);

            let fullSafetySize = 1 + clickNeighbors.length;

            let availableForBombs = fieldSize - fullSafetySize;

            if (bombCount <= availableForBombs) {
                forbiddenIndices.push(clickIdx);
                clickNeighbors.forEach(function(neighbor) {
                    forbiddenIndices.push(neighbor.y * field + neighbor.x);
                });
            }
            else if (bombCount < fieldSize)
                forbiddenIndices.push(clickIdx);
            else {
                bombCount = fieldSize - 1;
                forbiddenIndices.push(clickIdx);
            }
        }

        let placedBombs = 0;
        let tempBombList = [];

        while (placedBombs < bombCount) {
            let randomIndex = Math.floor(Math.random() * fieldSize);
            if (forbiddenIndices.indexOf(randomIndex) !== -1) continue;

            let bombCell = fieldRepeater.itemAt(randomIndex);
            if (bombCell && !bombCell.isBomb) {
                bombCell.isBomb = true;
                bombCell.setCellBombCount(0);
                tempBombList.push(bombCell);
                placedBombs++;
            }
        }

        bombCellsList = tempBombList;

        for (let idx = 0; idx < fieldSize; idx++) {
            let targetCell = fieldRepeater.itemAt(idx);
            if (!targetCell || targetCell.isBomb) continue;

            let coords = cellToCoord(targetCell);
            let neighbors = getNeighborsCoords(coords.x, coords.y);
            let bombCounter = 0;

            neighbors.forEach(function(neighbor) {
                let neighborCell = getCell(neighbor.x, neighbor.y);
                if (neighborCell && neighborCell.isBomb) {
                    bombCounter++;
                }
            });
            targetCell.setCellBombCount(bombCounter);
        }
    }

    Timer {
        id: cascadeTimer
        interval: 25
        repeat: true
        running: false
        onTriggered: {
            if (openQueue.length === 0) {
                cascadeTimer.stop();
                checkWinCondition();
                return;
            }
            let cell = openQueue.shift();
            if (cell && !cell.opened && !cell.flaged && !cell.isBomb) {
                cell.opened = true;
                if (cell.bomb_count.text !== "") {
                    checkWinCondition();
                    return;
                }
                let coords = cellToCoord(cell);

                let allNeighbors = getNeighborsCoords(coords.x, coords.y);
                allNeighbors.forEach(function(neighbor) {
                    let neighborCell = getCell(neighbor.x, neighbor.y);
                    if (neighborCell && !neighborCell.opened && !neighborCell.flaged && !neighborCell.isBomb) {
                        if (neighborCell.bomb_count.text !== "") {
                            neighborCell.opened = true;
                            checkWinCondition();
                        }
                    }
                });

                let crossNeighbors = getCrossNeighborsCoords(coords.x, coords.y);
                crossNeighbors.forEach(function(neighbor) {
                    let neighborCell = getCell(neighbor.x, neighbor.y);
                    if (neighborCell && !neighborCell.opened && !neighborCell.flaged && !neighborCell.isBomb) {
                        if (neighborCell.bomb_count.text === "" && openQueue.indexOf(neighborCell) === -1) {
                            openQueue.push(neighborCell);
                        }
                    }
                });
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.darker("#19171c", 1.2)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 100

            Text {
                id: flagCount
                Layout.leftMargin: 25
                Layout.topMargin: 25
                Layout.alignment: Qt.AlignTop
                text: flaggedCellsList.length + "/" + bombCount

                font.pixelSize: 24
                onTextChanged: {
                    let color = isWin ? Qt.lighter("green", 2) : "white"

                    if (flaggedCellsList.length > bombCount)
                        color = "red"
                    else if (flaggedCellsList.length === bombCount)
                        color = "yellow"

                    flagCount.color = color;
                }

            }
            Text {
                id: winOrLose
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.leftMargin: 100
                text: ""

                font.pixelSize: 24
                color: "white"
            }

            Item { Layout.fillWidth: true }
            RectButton {
                id: restartButton
                Layout.preferredHeight: 65
                Layout.preferredWidth: 65
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 25

                radius: 15

                colorControls:
                    [ Qt.lighter("#17151a", 1.25),
                      Qt.lighter("#17151a", 1.5),
                      Qt.lighter("#17151a", 2), ]
                scaleControls: [1, 1.05, 1.1]
                opacityAnim: false; opacity: 1

                iconSource: "data/restart.png"
                iconWidth: 35
                iconHeight: 35

                onTouched: {
                    clearField();
                    gameStarted = true;
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#3f3942"
        }
        Item {
            id: fieldArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: gridContainer
                anchors.horizontalCenter: parent.horizontalCenter
                property int availableWidth: window.width - 30
                property int availableHeight: window.height - 125 - 40
                property int calculatedCellSize: Math.floor(Math.min(availableWidth, availableHeight) / field)
                width: calculatedCellSize * field
                height: calculatedCellSize * field

                GridLayout {
                    id: fieldGrid
                    anchors.fill: parent
                    anchors.top: parent.top

                    columns: field
                    rows: field
                    rowSpacing: 0
                    columnSpacing: 0

                    Repeater {
                        id: fieldRepeater
                        model: field * field
                        Cell {
                            id: cell
                            cellIndex: index

                            Layout.preferredWidth: gridContainer.calculatedCellSize
                            Layout.preferredHeight: gridContainer.calculatedCellSize
                            flagImage.width: Math.floor(gridContainer.calculatedCellSize * 0.5)
                            flagImage.height: Math.floor(gridContainer.calculatedCellSize * 0.5)
                            bomb_count.font.pixelSize: Math.floor(gridContainer.calculatedCellSize * 0.45)
                            onTriggerEnable: setHoverZone(cell, true)
                            onTriggerDisable: setHoverZone(cell, false)
                            onTriggerOpen: setOpenCell(cell)
                            onTriggerFlag: toggleFlag(cell)
                            root: window
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 85

            RectButton {
                Layout.fillHeight: true; Layout.preferredWidth: 85

                radius: 25

                iconSource: "data/home.svg"; iconWidth: 50; iconHeight: 50
            }
        }
    }
}
