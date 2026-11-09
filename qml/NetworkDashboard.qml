import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    color: "#0a0b0e"

    // Zero-Overhead Hardware Caching [Change 12]
    layer.enabled: true
    layer.smooth: true

    signal serverSelected(string url, string name)
    signal closeDashboard()

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
                text: "Network Streams & Homelab Hub"
                color: "white"
                font.pixelSize: 22
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: 34
                Layout.preferredWidth: addServerText.implicitWidth + 24
                radius: 17
                color: addServerMouse.containsMouse ? "#ffa622" : Qt.rgba(1, 1, 1, 0.1)
                border.color: addServerMouse.containsMouse ? "#ffa622" : Qt.rgba(1, 1, 1, 0.2)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: addServerText
                    anchors.centerIn: parent
                    text: "+ Add Server / Stream..."
                    color: addServerMouse.containsMouse ? "#111111" : "white"
                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: addServerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: addServerDialog.open()
                }
            }

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
                    onClicked: root.closeDashboard()
                }
            }
        }
    }

    // Grid of Saved Network Nodes
    GridView {
        id: gridView
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 32
        clip: true

        cellWidth: Math.floor((width - 24) / Math.max(1, Math.floor(width / 340)))
        cellHeight: 180

        model: networkServerModel

        delegate: Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 10
                radius: 14
                color: Qt.rgba(0.12, 0.14, 0.19, 0.9)
                border.color: cardMouse.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.1)
                border.width: cardMouse.containsMouse ? 2 : 1
                scale: cardMouse.containsMouse ? 1.02 : 1.0

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        // Protocol Pill Badge
                        Rectangle {
                            height: 24
                            width: protoText.implicitWidth + 14
                            radius: 6
                            color: {
                                if (model.protocol === "SMB") return "#0a84ff";
                                if (model.protocol === "HTTP" || model.protocol === "HTTPS") return "#30d158";
                                if (model.protocol === "DLNA") return "#bf5af2";
                                return "#ff9f0a";
                            }

                            Text {
                                id: protoText
                                anchors.centerIn: parent
                                text: model.protocol
                                font.pixelSize: 11
                                font.bold: true
                                color: "white"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Online Status Indicator
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: model.isOnline ? "#30d158" : "#ff453a"
                        }
                        Text {
                            text: model.isOnline ? "Online" : "Offline"
                            color: model.isOnline ? "#30d158" : "#ff453a"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        text: model.name
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: model.description
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: model.serverUrl
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 11
                            font.family: "Monospace"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.mediaCount > 0 ? (model.mediaCount + " items") : ""
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.pixelSize: 11
                        }
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        networkServerModel.connectServer(index);
                        root.serverSelected(model.serverUrl, model.name);
                    }
                }
            }
        }
    }

    // Quick Add Server Dialog
    Dialog {
        id: addServerDialog
        title: "Add Network Server"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            spacing: 12
            width: 320

            TextField {
                id: sName
                placeholderText: "Friendly Name (e.g. Synology NAS)"
                Layout.fillWidth: true
            }

            ComboBox {
                id: sProto
                model: ["SMB", "HTTP", "HTTPS", "NFS", "SFTP", "DLNA"]
                Layout.fillWidth: true
            }

            TextField {
                id: sUrl
                placeholderText: "URL (e.g. smb://192.168.1.50/videos)"
                Layout.fillWidth: true
            }

            TextField {
                id: sDesc
                placeholderText: "Description (optional)"
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            if (sName.text.length > 0 && sUrl.text.length > 0) {
                networkServerModel.addServer(sName.text, sProto.currentText, sUrl.text, sDesc.text);
            }
        }
    }
}

