import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    color: "#0c0d10"

    signal mediaSelected(int index, string fileUrl)
    signal closeLibrary()

    // Header Bar
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 72
        color: Qt.rgba(0.08, 0.09, 0.12, 0.95)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            spacing: 20

            Text {
                text: "Media Library"
                color: "white"
                font.pixelSize: 22
                font.bold: true
            }

            Rectangle {
                Layout.preferredWidth: 280
                Layout.preferredHeight: 38
                radius: 19
                color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Canvas {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        Layout.alignment: Qt.AlignVCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.6);
                            ctx.lineWidth = 1.5;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(5.5, 5.5, 4.0, 0, 2 * Math.PI);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(8.5, 8.5); ctx.lineTo(12.5, 12.5);
                            ctx.stroke();
                        }
                    }

                    TextInput {
                        Layout.fillWidth: true
                        color: "white"
                        font.pixelSize: 13
                        // Placeholder
                        Text {
                            text: "Search local movies, shows..."
                            color: Qt.rgba(1, 1, 1, 0.4)
                            visible: parent.text.length === 0
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: 34
                Layout.preferredWidth: addFolderText.implicitWidth + 24
                radius: 17
                color: addFolderMouse.containsMouse ? "#ffa622" : Qt.rgba(1, 1, 1, 0.1)
                border.color: addFolderMouse.containsMouse ? "#ffa622" : Qt.rgba(1, 1, 1, 0.2)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: addFolderText
                    anchors.centerIn: parent
                    text: "+ Add Folder..."
                    color: addFolderMouse.containsMouse ? "#111111" : "white"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: addFolderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Close / Return to Player Button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: closeBtnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)

                Canvas {
                    anchors.centerIn: parent
                    width: 14; height: 14
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "white";
                        ctx.lineWidth = 1.6;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.moveTo(2, 2); ctx.lineTo(12, 12);
                        ctx.moveTo(12, 2); ctx.lineTo(2, 12);
                        ctx.stroke();
                    }
                }

                MouseArea {
                    id: closeBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeLibrary()
                }
            }
        }
    }

    // Grid View of Posters
    GridView {
        id: gridView
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28
        clip: true

        cellWidth: Math.floor((width - 20) / Math.max(2, Math.floor(width / 240)))
        cellHeight: cellWidth * 1.55

        model: mediaLibraryModel

        delegate: Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            Rectangle {
                id: card
                anchors.fill: parent
                anchors.margins: 10
                radius: 12
                color: Qt.rgba(0.12, 0.13, 0.17, 0.85)
                border.color: mouseArea.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.1)
                border.width: mouseArea.containsMouse ? 2 : 1
                scale: mouseArea.containsMouse ? 1.03 : 1.0

                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                // Poster Image / Placeholder with Gradient
                Rectangle {
                    id: posterBox
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * 0.72
                    radius: 10
                    color: Qt.rgba(0.18, 0.20, 0.26, 1.0)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: model.thumbnailUrl ? model.thumbnailUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Fallback poster artwork icon
                    Canvas {
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        opacity: 0.35
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "white";
                            ctx.fillStyle = "white";
                            ctx.lineWidth = 2.0;
                            ctx.lineCap = "round";
                            // Film clapboard rectangle
                            ctx.strokeRect(4, 10, 40, 30);
                            // Play triangle inside
                            ctx.beginPath();
                            ctx.moveTo(20, 18);
                            ctx.lineTo(32, 25);
                            ctx.lineTo(20, 32);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }

                    // Duration Badge (Overlay pill)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 8
                        height: 22
                        width: durationLabel.implicitWidth + 12
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.75)

                        Text {
                            id: durationLabel
                            anchors.centerIn: parent
                            text: model.durationStr
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "Monospace"
                        }
                    }

                    // Resolution Tag
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 8
                        height: 20
                        width: resLabel.implicitWidth + 10
                        radius: 4
                        color: Qt.rgba(0.1, 0.45, 0.9, 0.85)

                        Text {
                            id: resLabel
                            anchors.centerIn: parent
                            text: model.resolution.indexOf("4K") !== -1 ? "4K UHD" : "HD"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                // Metadata Area
                ColumnLayout {
                    anchors.top: posterBox.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 3

                    Text {
                        text: model.title
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: model.codec + " | " + model.fileSize
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mediaLibraryModel.playItem(index);
                        root.mediaSelected(index, model.fileUrl);
                    }
                }
            }
        }
    }
}

