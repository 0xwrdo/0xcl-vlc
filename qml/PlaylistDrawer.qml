import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property bool opened: false
    function open() { opened = true; }
    function close() { opened = false; }
    function toggle() { opened = !opened; }

    width: 340
    height: parent ? parent.height : 720
    visible: opened || (opacity > 0.01)
    enabled: opened
    opacity: opened ? 1.0 : 0.0
    x: opened ? 0 : -width

    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.08, 0.09, 0.13, 0.98)
        clip: false

        // Right subtle vertical border divider
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Qt.rgba(255, 255, 255, 0.14)
        }

        // Right edge soft drop shadow
        Rectangle {
            anchors.left: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 14
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Item {
            anchors.fill: parent
            clip: true

            // Top Header (54px)
            Rectangle {
                id: header
                width: parent.width
                height: 54
                color: Qt.rgba(0, 0, 0, 0.35)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14

                    Text {
                        text: "Play Queue"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Item count badge
                    Rectangle {
                        height: 20
                        width: countLabel.implicitWidth + 12
                        radius: 10
                        color: Qt.rgba(255, 149, 0, 0.18)
                        border.color: "#ff9500"
                        border.width: 1

                        Text {
                            id: countLabel
                            anchors.centerIn: parent
                            text: mediaLibraryModel.count + " items"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#ff9500"
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: closeArea.containsMouse ? Qt.rgba(255, 255, 255, 0.20) : "transparent"

                        Canvas {
                            anchors.centerIn: parent
                            width: 11; height: 11
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = "white";
                                ctx.lineWidth = 1.6;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.moveTo(1.5, 1.5); ctx.lineTo(9.5, 9.5);
                                ctx.moveTo(9.5, 1.5); ctx.lineTo(1.5, 9.5);
                                ctx.stroke();
                            }
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                        ModernToolTip { visible: closeArea.containsMouse; text: "Close Queue (Ctrl+Q)" }
                    }
                }

                // Divider line below header
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.08)
                }
            }

            // Action Toolbar
            RowLayout {
                id: actionToolbar
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                spacing: 8

                // Clear button
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 7
                    color: clearArea.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Clear Queue"
                        font.pixelSize: 12
                        font.bold: true
                        color: clearArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.75)
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaLibraryModel.clear()
                    }
                }
            }

            // Empty state placeholder
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: playlistView.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Queue is empty"
                    font.pixelSize: 15
                    font.bold: true
                    color: Qt.rgba(255, 255, 255, 0.45)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Drop files or open media to populate"
                    font.pixelSize: 12
                    color: Qt.rgba(255, 255, 255, 0.25)
                }
            }

            // Playlist Items
            ListView {
                id: playlistView
                anchors.top: actionToolbar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                clip: true
                spacing: 6

                model: mediaLibraryModel

                delegate: Rectangle {
                    width: playlistView.width
                    height: 52
                    radius: 8
                    color: itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : (index === 0 ? Qt.rgba(255, 149, 0, 0.12) : Qt.rgba(255, 255, 255, 0.03))
                    border.color: index === 0 ? "#ff9500" : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 10

                        // Track number or playing indicator
                        Text {
                            text: index === 0 ? ">" : (index + 1)
                            color: index === 0 ? "#ff9500" : Qt.rgba(255, 255, 255, 0.45)
                            font.pixelSize: 12
                            font.bold: true
                            Layout.preferredWidth: 16
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: model.title
                                color: index === 0 ? "#ff9500" : "white"
                                font.pixelSize: 13
                                font.bold: index === 0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: model.codec + " | " + model.fileSize
                                color: Qt.rgba(255, 255, 255, 0.50)
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        // Remove item button
                        Rectangle {
                            width: 24; height: 24; radius: 12
                            color: delMouse.containsMouse ? Qt.rgba(232, 17, 35, 0.3) : "transparent"

                            Canvas {
                                anchors.centerIn: parent
                                width: 8; height: 8
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = delMouse.containsMouse ? "#e81123" : Qt.rgba(255, 255, 255, 0.45);
                                    ctx.lineWidth = 1.3;
                                    ctx.lineCap = "round";
                                    ctx.beginPath();
                                    ctx.moveTo(1, 1); ctx.lineTo(7, 7);
                                    ctx.moveTo(7, 1); ctx.lineTo(1, 7);
                                    ctx.stroke();
                                }
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mediaLibraryModel.removeIndex(index)
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        anchors.rightMargin: 34
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mediaLibraryModel.playItem(index);
                            playerController.openFile(model.fileUrl);
                            videoSurface.openFile(model.fileUrl);
                        }
                    }
                }
            }
        }
    }
}
