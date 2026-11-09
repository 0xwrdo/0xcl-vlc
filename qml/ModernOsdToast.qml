import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property string iconText: "VOL"
    property string titleText: "Volume"
    property string valueText: "85%"
    property real progressValue: -1 // -1 to disable progress bar
    property bool isActive: false

    layer.enabled: true
    layer.smooth: true

    implicitWidth: toastCard.width
    implicitHeight: toastCard.height

    function showToast(icon, title, value, progress = -1) {
        root.iconText = icon;
        root.titleText = title;
        root.valueText = value ? value : "";
        root.progressValue = progress;
        root.isActive = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1400
        repeat: false
        onTriggered: root.isActive = false
    }

    Rectangle {
        id: toastCard
        width: Math.max(160, contentRow.implicitWidth + 36)
        height: root.progressValue >= 0 ? 46 : 38
        radius: height / 2
        anchors.centerIn: parent

        // Sleek frosted acrylic pill
        color: Qt.rgba(0.06, 0.07, 0.10, 0.94)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1

        opacity: root.isActive ? 1.0 : 0.0
        scale: root.isActive ? 1.0 : 0.92

        Behavior on opacity {
            OpacityAnimator { duration: 140; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            spacing: 2

            RowLayout {
                id: contentRow
                Layout.fillWidth: true
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                // Vector Icon for OSD Action
                Canvas {
                    id: osdIconCanvas
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = "#ff9500";
                        ctx.strokeStyle = "#ff9500";
                        ctx.lineWidth = 1.4;
                        ctx.lineCap = "round";

                        if (root.iconText === "PLAY") {
                            // Play triangle
                            ctx.beginPath();
                            ctx.moveTo(3, 1.5);
                            ctx.lineTo(14, 8);
                            ctx.lineTo(3, 14.5);
                            ctx.closePath();
                            ctx.fill();
                        } else if (root.iconText === "PAUSE") {
                            // Two pause bars
                            ctx.fillRect(2.5, 2, 3.5, 12);
                            ctx.fillRect(10.0, 2, 3.5, 12);
                        } else if (root.iconText === "MUTE") {
                            // Speaker with X
                            ctx.beginPath();
                            ctx.moveTo(2, 5.5); ctx.lineTo(5, 5.5); ctx.lineTo(8.5, 2.5);
                            ctx.lineTo(8.5, 13.5); ctx.lineTo(5, 10.5); ctx.lineTo(2, 10.5);
                            ctx.closePath();
                            ctx.fill();
                            ctx.strokeStyle = "#ff453a";
                            ctx.beginPath();
                            ctx.moveTo(11, 5.5); ctx.lineTo(15, 10.5);
                            ctx.moveTo(15, 5.5); ctx.lineTo(11, 10.5);
                            ctx.stroke();
                        } else if (root.iconText === "VOL" || root.iconText === "BOOST") {
                            // Speaker with wave
                            ctx.beginPath();
                            ctx.moveTo(2, 5.5); ctx.lineTo(5, 5.5); ctx.lineTo(8.5, 2.5);
                            ctx.lineTo(8.5, 13.5); ctx.lineTo(5, 10.5); ctx.lineTo(2, 10.5);
                            ctx.closePath();
                            ctx.fill();
                            ctx.beginPath();
                            ctx.arc(8, 8, 4.5, -Math.PI / 3, Math.PI / 3, false);
                            ctx.stroke();
                        } else if (root.iconText.indexOf("10s") !== -1 || root.iconText.indexOf("5s") !== -1) {
                            // Seek icon
                            ctx.beginPath();
                            if (root.iconText.indexOf("-") !== -1) {
                                ctx.moveTo(9, 3); ctx.lineTo(3, 8); ctx.lineTo(9, 13);
                                ctx.moveTo(14, 3); ctx.lineTo(8, 8); ctx.lineTo(14, 13);
                            } else {
                                ctx.moveTo(3, 3); ctx.lineTo(9, 8); ctx.lineTo(3, 13);
                                ctx.moveTo(8, 3); ctx.lineTo(14, 8); ctx.lineTo(8, 13);
                            }
                            ctx.stroke();
                        } else {
                            // Generic badge for other notifications
                            ctx.strokeStyle = "#ff9500";
                            ctx.strokeRect(1, 3, 14, 10);
                        }
                    }

                    Connections {
                        target: root
                        function onIconTextChanged() { osdIconCanvas.requestPaint(); }
                    }
                }

                // OSD Title Text (e.g. "Paused", "Playing", "Volume")
                Text {
                    text: root.titleText
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true; visible: root.valueText.length > 0 }

                // OSD Value Text (e.g. "85%", "1.25x")
                Text {
                    text: root.valueText
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Monospace"
                    color: "#ff9500"
                    visible: root.valueText.length > 0
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // OSD Progress Bar (for Volume / Overdrive)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 1.5
                color: Qt.rgba(1, 1, 1, 0.18)
                visible: root.progressValue >= 0

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * (root.progressValue / 1.25)))
                    height: parent.height
                    radius: 1.5
                    color: (root.progressValue > 1.0) ? "#ff453a" : "#ff9500"
                }
            }
        }
    }
}
