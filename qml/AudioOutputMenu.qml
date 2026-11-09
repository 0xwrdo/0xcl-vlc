import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property bool opened: false
    property var videoSurface: null
    property var playerController: null

    property var audioDevices: (videoSurface && videoSurface.audioDevices && videoSurface.audioDevices.length > 0)
                               ? videoSurface.audioDevices
                               : (playerController ? playerController.audioDevices : [])

    property string currentAudioDevice: (videoSurface && videoSurface.currentAudioDevice)
                                        ? videoSurface.currentAudioDevice
                                        : (playerController ? playerController.currentAudioDevice : "")

    signal deviceSelected(string deviceName)

    function open() {
        if (videoSurface) videoSurface.refreshAudioDevices();
        if (playerController) playerController.refreshAudioDevices();
        opened = true;
    }
    function close() { opened = false; }
    function toggle() {
        if (opened) close();
        else open();
    }

    width: 290
    height: Math.min(320, (deviceList.count * 52) + 54)
    visible: opacity > 0.0
    opacity: opened ? 1.0 : 0.0
    scale: opened ? 1.0 : 0.94
    transformOrigin: Item.BottomRight

    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(0.08, 0.09, 0.13, 0.98)
        border.color: Qt.rgba(255, 255, 255, 0.16)
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header (Refined 38px)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                color: Qt.rgba(0, 0, 0, 0.35)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10

                    Text {
                        text: "AUDIO OUTPUT DESTINATION"
                        color: Qt.rgba(255, 255, 255, 0.65)
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.9
                        Layout.fillWidth: true
                    }

                    // Refresh Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: refreshMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : "transparent"

                        Canvas {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = refreshMouse.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.70);
                                ctx.lineWidth = 1.3;
                                ctx.beginPath();
                                ctx.arc(6.0, 6.0, 4.2, 0.2, 1.8 * Math.PI);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(8.0, 1.2); ctx.lineTo(10.2, 2.8); ctx.lineTo(8.0, 4.4);
                                ctx.stroke();
                            }
                            Connections {
                                target: refreshMouse
                                function onContainsMouseChanged() { parent.requestPaint(); }
                            }
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.videoSurface) root.videoSurface.refreshAudioDevices();
                                if (root.playerController) root.playerController.refreshAudioDevices();
                            }
                        }
                        ModernToolTip { visible: refreshMouse.containsMouse; text: "Rescan Audio Hardware" }
                    }

                    // Close Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: closeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : "transparent"

                        Canvas {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.70);
                                ctx.lineWidth = 1.3;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.moveTo(1.0, 1.0); ctx.lineTo(9.0, 9.0);
                                ctx.moveTo(9.0, 1.0); ctx.lineTo(1.0, 9.0);
                                ctx.stroke();
                            }
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                // Subtle bottom divider
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.08)
                }
            }

            // Device List with comfortable spacing
            ListView {
                id: deviceList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 6
                clip: true
                spacing: 5
                model: root.audioDevices
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: devDelegate
                    width: deviceList.width
                    height: 46
                    color: "transparent"

                    property bool isActive: (modelData.id === root.currentAudioDevice || modelData.name === root.currentAudioDevice)
                    property string devType: modelData.type ? modelData.type : "speaker"

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: devMouse.pressed 
                               ? Qt.rgba(255, 255, 255, 0.18) 
                               : (devMouse.containsMouse 
                                  ? Qt.rgba(255, 255, 255, 0.10) 
                                  : (devDelegate.isActive ? Qt.rgba(255, 149, 0, 0.12) : "transparent"))
                        border.color: devDelegate.isActive 
                                      ? Qt.rgba(255, 149, 0, 0.45) 
                                      : (devMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 10
                            spacing: 10

                            // Icon Container Capsule
                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                Layout.alignment: Qt.AlignVCenter
                                radius: 7
                                color: devDelegate.isActive 
                                       ? Qt.rgba(255, 149, 0, 0.20) 
                                       : (devMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.05))

                                Canvas {
                                    id: devIconCanvas
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16

                                    property color iconColor: devDelegate.isActive 
                                                              ? "#ff9500" 
                                                              : (devMouse.containsMouse ? "#ffffff" : Qt.rgba(255, 255, 255, 0.75))

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = iconColor;
                                        ctx.fillStyle = iconColor;
                                        ctx.lineWidth = 1.3;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";

                                        if (devDelegate.devType === "headphones") {
                                            // Overhead arc headband
                                            ctx.beginPath();
                                            ctx.arc(8.0, 8.5, 6.0, Math.PI, 2 * Math.PI, false);
                                            ctx.stroke();
                                            // Left earcup
                                            ctx.beginPath();
                                            ctx.roundedRect(1.5, 8.0, 3.2, 6.0, 1.5, 1.5);
                                            ctx.fill();
                                            // Right earcup
                                            ctx.beginPath();
                                            ctx.roundedRect(11.3, 8.0, 3.2, 6.0, 1.5, 1.5);
                                            ctx.fill();
                                        } else if (devDelegate.devType === "bluetooth") {
                                            // Bluetooth geometric rune
                                            ctx.beginPath();
                                            ctx.moveTo(8.0, 1.5); ctx.lineTo(8.0, 14.5);
                                            ctx.moveTo(8.0, 1.5); ctx.lineTo(12.5, 5.0); ctx.lineTo(4.5, 11.0);
                                            ctx.moveTo(8.0, 14.5); ctx.lineTo(12.5, 11.0); ctx.lineTo(4.5, 5.0);
                                            ctx.stroke();
                                        } else if (devDelegate.devType === "hdmi") {
                                            // Display / HDMI monitor
                                            ctx.strokeRect(1.5, 2.0, 13.0, 9.0);
                                            ctx.beginPath();
                                            ctx.moveTo(8.0, 11.0); ctx.lineTo(8.0, 13.5);
                                            ctx.moveTo(5.0, 13.5); ctx.lineTo(11.0, 13.5);
                                            ctx.stroke();
                                        } else {
                                            // Speaker Driver
                                            ctx.beginPath();
                                            ctx.moveTo(2.0, 5.0); ctx.lineTo(5.0, 5.0); ctx.lineTo(9.0, 2.0);
                                            ctx.lineTo(9.0, 14.0); ctx.lineTo(5.0, 11.0); ctx.lineTo(2.0, 11.0);
                                            ctx.closePath();
                                            ctx.fill();
                                            // Sound wave arc
                                            ctx.beginPath();
                                            ctx.arc(9.0, 8.0, 4.0, -Math.PI / 3.0, Math.PI / 3.0, false);
                                            ctx.stroke();
                                        }
                                    }

                                    Connections {
                                        target: devMouse
                                        function onContainsMouseChanged() { devIconCanvas.requestPaint(); }
                                    }
                                    Connections {
                                        target: devDelegate
                                        function onIsActiveChanged() { devIconCanvas.requestPaint(); }
                                    }
                                }
                            }

                            // Device Name & Category Subtitle
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    id: devNameText
                                    text: modelData.name
                                    font.pixelSize: 12
                                    font.weight: devDelegate.isActive ? Font.DemiBold : Font.Normal
                                    color: devDelegate.isActive 
                                           ? "#ff9500" 
                                           : (devMouse.containsMouse ? "#ffffff" : Qt.rgba(255, 255, 255, 0.90))
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: devDelegate.devType === "headphones" ? "Headphones / Headset" : (devDelegate.devType === "bluetooth" ? "Bluetooth Audio" : (devDelegate.devType === "hdmi" ? "HDMI / DisplayPort" : "System Speakers"))
                                    font.pixelSize: 9
                                    font.weight: Font.Normal
                                    color: devDelegate.isActive ? Qt.rgba(255, 149, 0, 0.70) : Qt.rgba(255, 255, 255, 0.45)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Active Checkmark Indicator
                            Canvas {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                                visible: devDelegate.isActive

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = "#ff9500";
                                    ctx.lineWidth = 2.0;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.beginPath();
                                    ctx.moveTo(2.5, 8.0);
                                    ctx.lineTo(6.5, 12.0);
                                    ctx.lineTo(13.5, 4.0);
                                    ctx.stroke();
                                }
                            }
                        }

                        MouseArea {
                            id: devMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.videoSurface) {
                                    root.videoSurface.setAudioOutputDevice(modelData.id);
                                }
                                if (root.playerController) {
                                    root.playerController.setAudioOutputDevice(modelData.id);
                                }
                                root.deviceSelected(modelData.name);
                                root.close();
                            }
                        }

                        ModernToolTip {
                            visible: devMouse.containsMouse && devNameText.truncated
                            text: modelData.name
                        }
                    }
                }
            }
        }
    }
}
