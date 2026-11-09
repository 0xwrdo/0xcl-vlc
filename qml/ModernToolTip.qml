import QtQuick 2.15
import QtQuick.Controls 2.15

ToolTip {
    id: root

    delay: 300
    timeout: 4000
    topPadding: 7
    bottomPadding: 7
    leftPadding: 12
    rightPadding: 12

    y: -implicitHeight - 8

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 120; easing.type: Easing.OutQuad }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 90; easing.type: Easing.InQuad }
    }

    contentItem: Text {
        text: root.text
        color: "#ffffff"
        font.pixelSize: 11
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitHeight: 28
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.12, 0.14, 0.18, 0.98) }
            GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.07, 0.10, 0.98) }
        }
        border.color: Qt.rgba(255, 255, 255, 0.16)
        border.width: 1

        // Top subtle highlight edge
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            color: Qt.rgba(255, 255, 255, 0.12)
            radius: 6
        }
    }
}
