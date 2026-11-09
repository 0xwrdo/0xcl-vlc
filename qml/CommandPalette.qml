import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: root

    anchors.centerIn: parent
    width: Math.min(parent.width - 64, 560)
    height: 380
    modal: true
    focus: true

    signal actionTriggered(string commandId)

    background: Rectangle {
        radius: 14
        color: Qt.rgba(0.08, 0.09, 0.12, 0.96)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        layer.enabled: true
        layer.smooth: true
    }

    // Command List Model
    ListModel {
        id: commandList
        ListElement { name: "Toggle Play / Pause"; shortcut: "Space"; category: "Playback"; idStr: "play_pause" }
        ListElement { name: "Toggle Fullscreen Mode"; shortcut: "F"; category: "Window"; idStr: "fullscreen" }
        ListElement { name: "Toggle Picture in Picture (PiP)"; shortcut: "P"; category: "Window"; idStr: "pip" }
        ListElement { name: "Open Subtitle Synchronizer"; shortcut: "H / G"; category: "Subtitles"; idStr: "sub_sync" }
        ListElement { name: "Audio Equalizer (Bezier Studio)"; shortcut: "Ctrl+E"; category: "Audio"; idStr: "eq" }
        ListElement { name: "Show Stats for Nerds Telemetry"; shortcut: "Ctrl+I"; category: "Diagnostics"; idStr: "stats" }
        ListElement { name: "Browse Media Library Posters"; shortcut: "Ctrl+L"; category: "Library"; idStr: "medialib" }
        ListElement { name: "Open Network Streams Hub"; shortcut: "Ctrl+N"; category: "Network"; idStr: "network" }
        ListElement { name: "Take Instant Snapshot"; shortcut: "Shift+S"; category: "Video"; idStr: "snapshot" }
        ListElement { name: "Speed Up Playback (+0.1x)"; shortcut: "]"; category: "Playback"; idStr: "faster" }
        ListElement { name: "Slow Down Playback (-0.1x)"; shortcut: "["; category: "Playback"; idStr: "slower" }
        ListElement { name: "Reset Playback Speed (1.0x)"; shortcut: "="; category: "Playback"; idStr: "normalspeed" }
        ListElement { name: "Toggle Audio Track"; shortcut: "B"; category: "Audio"; idStr: "audio_track" }
        ListElement { name: "Toggle Audio Mute"; shortcut: "M"; category: "Audio"; idStr: "mute" }
        ListElement { name: "Toggle Subtitle Track"; shortcut: "V"; category: "Subtitles"; idStr: "sub_track" }
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Search Input Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: searchInput.activeFocus ? "#ff9500" : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                Canvas {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.7);
                        ctx.lineWidth = 1.6;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.arc(6.5, 6.5, 4.5, 0, 2 * Math.PI);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(10, 10);
                        ctx.lineTo(14, 14);
                        ctx.stroke();
                    }
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Type a command or hotkey (e.g. Play, Subtitles, Stats)..."
                    color: "white"
                    font.pixelSize: 14
                    background: null
                    focus: true
                }
            }
        }

        // Commands List View
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: commandList

            delegate: Rectangle {
                width: listView.width
                radius: 6
                color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                visible: searchInput.text.length === 0 || 
                         model.name.toLowerCase().indexOf(searchInput.text.toLowerCase()) !== -1 ||
                         model.category.toLowerCase().indexOf(searchInput.text.toLowerCase()) !== -1

                height: visible ? 42 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text {
                        text: model.category.toUpperCase()
                        color: "#ff9500"
                        font.pixelSize: 10
                        font.bold: true
                        Layout.preferredWidth: 80
                    }

                    Text {
                        text: model.name
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Hotkey badge
                    Rectangle {
                        height: 22
                        width: badgeText.implicitWidth + 12
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.12)
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                        border.width: 1

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: model.shortcut
                            color: Qt.rgba(1, 1, 1, 0.85)
                            font.pixelSize: 11
                            font.family: "Monospace"
                        }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.actionTriggered(model.idStr);
                        root.close();
                    }
                }
            }
        }
    }
}

