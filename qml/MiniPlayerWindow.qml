import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    id: pipWindow

    title: "VLC Mini-Player"
    width: 360
    height: 202
    minimumWidth: 240
    minimumHeight: 135

    // Always-on-top, frameless desktop PiP window
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    color: "#000000"

    signal returnToMain()
    signal playPauseClicked()

    property bool isPlaying: true

    DragHandler {
        target: null
        onActiveChanged: if (active) pipWindow.startSystemMove()
    }

    Rectangle {
        id: videoCanvas
        anchors.fill: parent
        color: "#0a0c10"
        border.color: Qt.rgba(1, 1, 1, 0.2)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "VLC Mini-Player (PiP)"
            color: Qt.rgba(1, 1, 1, 0.3)
            font.pixelSize: 14
            font.bold: true
        }

        // Hover Overlay Controls
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)
            opacity: pipMouse.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Top action buttons: Expand & Close
            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 8

                // Expand back to main
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: expandMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.5)

                    Canvas {
                        anchors.centerIn: parent
                        width: 11; height: 11
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "white";
                            ctx.lineWidth = 1.4;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(1, 3.5); ctx.lineTo(1, 1); ctx.lineTo(3.5, 1); ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(7.5, 1); ctx.lineTo(10, 1); ctx.lineTo(10, 3.5); ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(1, 7.5); ctx.lineTo(1, 10); ctx.lineTo(3.5, 10); ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(7.5, 10); ctx.lineTo(10, 10); ctx.lineTo(10, 7.5); ctx.stroke();
                        }
                    }

                    MouseArea {
                        id: expandMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: pipWindow.returnToMain()
                    }
                }

                // Close PiP
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: closeMouse.containsMouse ? "#e81123" : Qt.rgba(0, 0, 0, 0.5)

                    Canvas {
                        anchors.centerIn: parent
                        width: 9; height: 9
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "white";
                            ctx.lineWidth = 1.4;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(1, 1); ctx.lineTo(8, 8);
                            ctx.moveTo(8, 1); ctx.lineTo(1, 8);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: pipWindow.close()
                    }
                }
            }

            // Center Play/Pause
            Rectangle {
                width: 40; height: 40; radius: 20
                anchors.centerIn: parent
                color: "#ff9500"

                // Pause bars
                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    visible: pipWindow.isPlaying
                    Rectangle { width: 3; height: 12; radius: 1; color: "black" }
                    Rectangle { width: 3; height: 12; radius: 1; color: "black" }
                }

                // Play triangle
                Canvas {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1.5
                    width: 12; height: 14
                    visible: !pipWindow.isPlaying
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = "black";
                        ctx.beginPath();
                        ctx.moveTo(1, 1); ctx.lineTo(11, 7); ctx.lineTo(1, 13);
                        ctx.closePath();
                        ctx.fill();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pipWindow.isPlaying = !pipWindow.isPlaying;
                        pipWindow.playPauseClicked();
                    }
                }
            }
        }

        MouseArea {
            id: pipMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
}
