import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property int subtitleOffsetMs: 0
    property int maxOffsetRangeMs: 5000 // +/- 5000 ms range

    signal offsetChanged(int offsetMs)
    signal offsetReset()
    signal closeRequested()

    implicitWidth: Math.min(parent.width - 96, 560)
    implicitHeight: 44
    radius: 22

    color: Qt.rgba(0.08, 0.09, 0.12, 0.95)
    border.color: Qt.rgba(1, 1, 1, 0.14)
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 8

        // Subtitle Vector Badge
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 18
            radius: 4
            color: Qt.rgba(255, 149, 0, 0.18)
            border.color: "#ff9500"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "CC"
                font.pixelSize: 9
                font.bold: true
                color: "#ff9500"
            }
        }

        Text {
            text: "Sync"
            font.pixelSize: 11
            font.bold: true
            color: Qt.rgba(1, 1, 1, 0.70)
        }

        // -50ms Step Nudge Button
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 22
            radius: 6
            color: minusArea.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "-50"
                font.pixelSize: 9
                font.bold: true
                color: minusArea.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.85)
            }

            MouseArea {
                id: minusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var newOffset = Math.max(-root.maxOffsetRangeMs, root.subtitleOffsetMs - 50);
                    root.subtitleOffsetMs = newOffset;
                    root.offsetChanged(newOffset);
                }
            }
            ModernToolTip { visible: minusArea.containsMouse; text: "Nudge -50 ms" }
        }

        // Subtitle Offset Drag Track
        Item {
            id: trackItem
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            // Background Groove
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.12)

                // Center Zero Line Reference (visible when offset to show origin)
                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: 12
                    radius: 1
                    color: "#ff9500"
                    visible: Math.abs(root.subtitleOffsetMs) > 60
                }
            }

            // Click track to jump
            MouseArea {
                id: trackClickArea
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    var usableWidth = trackItem.width - thumb.width;
                    if (usableWidth > 0) {
                        var targetX = Math.max(0, Math.min(usableWidth, mouse.x - thumb.width / 2));
                        var ratio = targetX / usableWidth;
                        var offset = Math.round((ratio * 2.0 - 1.0) * root.maxOffsetRangeMs);
                        root.subtitleOffsetMs = offset;
                        root.offsetChanged(offset);
                    }
                }
            }

            // Draggable Offset Pill
            Rectangle {
                id: thumb
                width: 96
                height: 24
                radius: 12
                anchors.verticalCenter: parent.verticalCenter

                // Position based on offset
                x: {
                    var usableWidth = trackItem.width - width;
                    var ratio = (root.subtitleOffsetMs + root.maxOffsetRangeMs) / (2.0 * root.maxOffsetRangeMs);
                    return Math.max(0, Math.min(usableWidth, ratio * usableWidth));
                }

                color: dragArea.drag.active ? "#ffa622" : (root.subtitleOffsetMs === 0 ? Qt.rgba(1, 1, 1, 0.16) : "#ff9500")
                border.color: root.subtitleOffsetMs === 0 ? Qt.rgba(1, 1, 1, 0.35) : "white"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (root.subtitleOffsetMs === 0) return "In Sync (0 ms)";
                        var prefix = root.subtitleOffsetMs > 0 ? "+" : "";
                        return prefix + root.subtitleOffsetMs + " ms";
                    }
                    color: root.subtitleOffsetMs === 0 ? "white" : "#111111"
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "Monospace"
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor
                    drag.target: thumb
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: trackItem.width - thumb.width

                    onPositionChanged: {
                        if (drag.active) {
                            var usableWidth = trackItem.width - thumb.width;
                            if (usableWidth > 0) {
                                var ratio = thumb.x / usableWidth; // 0.0 to 1.0
                                var offset = Math.round((ratio * 2.0 - 1.0) * root.maxOffsetRangeMs);
                                root.subtitleOffsetMs = offset;
                                root.offsetChanged(offset);
                            }
                        }
                    }

                    onDoubleClicked: {
                        root.subtitleOffsetMs = 0;
                        root.offsetReset();
                    }
                }
            }
        }

        // +50ms Step Nudge Button
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 22
            radius: 6
            color: plusArea.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "+50"
                font.pixelSize: 9
                font.bold: true
                color: plusArea.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.85)
            }

            MouseArea {
                id: plusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var newOffset = Math.min(root.maxOffsetRangeMs, root.subtitleOffsetMs + 50);
                    root.subtitleOffsetMs = newOffset;
                    root.offsetChanged(newOffset);
                }
            }
            ModernToolTip { visible: plusArea.containsMouse; text: "Nudge +50 ms" }
        }

        // Quick Reset Button (0ms)
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: resetMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            visible: root.subtitleOffsetMs !== 0

            Text {
                anchors.centerIn: parent
                text: "0"
                font.pixelSize: 11
                font.bold: true
                color: resetMouse.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.7)
            }

            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.subtitleOffsetMs = 0;
                    root.offsetReset();
                }
            }

            ModernToolTip { visible: resetMouse.containsMouse; text: "Reset to 0 ms" }
        }

        // Close Bar Button (Vector Canvas Cross)
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: closeMouse.containsMouse ? Qt.rgba(232, 17, 35, 0.35) : "transparent"

            Canvas {
                anchors.centerIn: parent
                width: 10
                height: 10
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = closeMouse.containsMouse ? "#e81123" : Qt.rgba(1, 1, 1, 0.75);
                    ctx.lineWidth = 1.4;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.moveTo(1, 1); ctx.lineTo(9, 9);
                    ctx.moveTo(9, 1); ctx.lineTo(1, 9);
                    ctx.stroke();
                }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }

            ModernToolTip { visible: closeMouse.containsMouse; text: "Dismiss" }
        }
    }
}
