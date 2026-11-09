import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    property real posA: 0.15 // 0.0 to 1.0
    property real posB: 0.45 // 0.0 to 1.0
    property bool loopActive: false

    signal loopRangeChanged(real a, real b)
    signal loopToggled(bool active)

    implicitWidth: 600
    implicitHeight: 28

    layer.enabled: true
    layer.smooth: true

    Rectangle {
        id: barTrack
        anchors.fill: parent
        radius: 4
        color: Qt.rgba(0.12, 0.14, 0.18, 0.6)
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        // Highlighted Loop Region Strip
        Rectangle {
            x: root.posA * barTrack.width
            width: Math.max(8, (root.posB - root.posA) * barTrack.width)
            height: parent.height
            color: root.loopActive ? Qt.rgba(0, 190, 255, 0.35) : Qt.rgba(255, 149, 0, 0.25)
            border.color: root.loopActive ? "#00c3ff" : "#ff9500"
            border.width: 1
        }

        // Handle Flag A
        Rectangle {
            id: handleA
            width: 18
            height: 22
            radius: 3
            x: root.posA * barTrack.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: "#ff9500"

            Text {
                anchors.centerIn: parent
                text: "A"
                font.pixelSize: 11
                font.bold: true
                color: "black"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.target: handleA
                drag.axis: Drag.XAxis
                drag.minimumX: 0
                drag.maximumX: handleB.x - 10

                onPositionChanged: {
                    if (drag.active) {
                        root.posA = Math.max(0.0, Math.min(root.posB - 0.02, (handleA.x + handleA.width / 2) / barTrack.width));
                        root.loopRangeChanged(root.posA, root.posB);
                    }
                }
            }
        }

        // Handle Flag B
        Rectangle {
            id: handleB
            width: 18
            height: 22
            radius: 3
            x: root.posB * barTrack.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: "#0a84ff"

            Text {
                anchors.centerIn: parent
                text: "B"
                font.pixelSize: 11
                font.bold: true
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.target: handleB
                drag.axis: Drag.XAxis
                drag.minimumX: handleA.x + 10
                drag.maximumX: barTrack.width - width

                onPositionChanged: {
                    if (drag.active) {
                        root.posB = Math.max(root.posA + 0.02, Math.min(1.0, (handleB.x + handleB.width / 2) / barTrack.width));
                        root.loopRangeChanged(root.posA, root.posB);
                    }
                }
            }
        }
    }
}

