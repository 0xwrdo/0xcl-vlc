import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Item {
    id: root

    property int activeTab: 0
    property var videoSurface: null
    property bool opened: false

    function open() { opened = true; }
    function close() { opened = false; }
    function toggle() { opened = !opened; }

    width: 310
    height: Math.min(parent ? parent.height - 110 : 360, (root.activeTab === 0 ? 210 : (root.activeTab === 1 ? 260 : 380)))
    visible: opacity > 0.0
    opacity: opened ? 1.0 : 0.0
    scale: opened ? 1.0 : 0.95
    transformOrigin: Item.BottomRight
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    FileDialog {
        id: subtitleDialog
        title: "Select Subtitle File"
        nameFilters: ["Subtitle Files (*.srt *.sub *.vtt *.ass *.ssa *.idx *.txt)", "All Files (*)"]
        onAccepted: {
            if (root.videoSurface) {
                root.videoSurface.addSubtitleFile(subtitleDialog.selectedFile);
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(0.08, 0.09, 0.12, 0.96)
        border.color: Qt.rgba(255, 255, 255, 0.15)
        border.width: 1
        clip: true

        Item {
            anchors.fill: parent

        // Top Header (Compact 42px)
        Rectangle {
            id: header
            width: parent.width
            height: 42
            color: Qt.rgba(0, 0, 0, 0.3)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12

                Text {
                    text: "Playback Settings"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                // Close Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"

                    Canvas {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "white";
                            ctx.lineWidth = 1.4;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(1, 1); ctx.lineTo(9, 9);
                            ctx.moveTo(9, 1); ctx.lineTo(1, 9);
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
                }
            }
        }

        // Segmented Tab Selector (Audio, Subtitles, Bezier EQ, Video)
        Rectangle {
            id: tabSelectorBar
            anchors.top: header.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            height: 30
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.06)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: ["Audio", "Subtitles", "Bezier EQ", "Video"]

                    delegate: Rectangle {
                        id: tabItem
                        width: (tabSelectorBar.width - 6 - (3 * 3)) / 4
                        height: parent.height
                        radius: 6

                        property bool isSelected: root.activeTab === index
                        color: isSelected 
                               ? "#ff9500" 
                               : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")

                        Behavior on color { ColorAnimation { duration: 130 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.bold: tabItem.isSelected
                            color: tabItem.isSelected ? "#111111" : (tabMouse.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.75))
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = index;
                            }
                        }
                    }
                }
            }
        }

        // Tab Content Pages
        StackLayout {
            id: stackLayout
            anchors.top: tabSelectorBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 18
            currentIndex: root.activeTab

            // ========================================================
            // 1. Audio Page
            // ========================================================
            ScrollView {
                id: audioScroll
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: audioScroll.availableWidth
                    spacing: 14

                    Text {
                        text: "AUDIO TRACKS"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        font.bold: true
                    }

                    // Disable Audio Option
                    Rectangle {
                        id: disableAudioOption
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 6
                        property bool isChecked: root.videoSurface ? (root.videoSurface.currentAudioTrack === -1) : false
                        color: disableAudioMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : (isChecked ? Qt.rgba(255, 149, 0, 0.12) : "transparent")
                        border.color: isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                radius: 9
                                color: "transparent"
                                border.color: disableAudioOption.isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.4)
                                border.width: disableAudioOption.isChecked ? 2 : 1.5

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8; height: 8; radius: 4
                                    color: "#ff9500"
                                    visible: disableAudioOption.isChecked
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Disable Audio"
                                color: disableAudioOption.isChecked ? "#ff9500" : "white"
                                font.pixelSize: 13
                                font.bold: disableAudioOption.isChecked
                            }
                        }

                        MouseArea {
                            id: disableAudioMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.videoSurface) root.videoSurface.setAudioTrack(-1);
                            }
                        }
                    }

                    // Dynamic Audio Tracks List
                    Repeater {
                        model: (root.videoSurface && root.videoSurface.audioTracks && root.videoSurface.audioTracks.length > 0)
                               ? root.videoSurface.audioTracks
                                : ["Track 1: Stereo [Default]"]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 6
                            property bool isChecked: (root.videoSurface ? root.videoSurface.currentAudioTrack : 0) === index
                            color: audioTrackMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : (isChecked ? Qt.rgba(255, 149, 0, 0.12) : "transparent")
                            border.color: isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Custom styled radio indicator
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "transparent"
                                    border.color: isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.4)
                                    border.width: isChecked ? 2 : 1.5

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8; height: 8; radius: 4
                                        color: "#ff9500"
                                        visible: isChecked
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 30
                                    text: modelData
                                    color: isChecked ? "#ff9500" : "white"
                                    font.pixelSize: 13
                                    font.bold: isChecked
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: audioTrackMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.videoSurface) root.videoSurface.setAudioTrack(index);
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    Text {
                        text: "STEREO MODE"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        font.bold: true
                    }

                    ComboBox {
                        id: stereoBox
                        Layout.fillWidth: true
                        model: ["Original", "Stereo Downmix", "Headphones Surround (Binaural)", "Left", "Right"]

                        contentItem: Text {
                            text: stereoBox.displayText
                            font.pixelSize: 13
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 12
                        }

                        background: Rectangle {
                            implicitHeight: 38
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.color: stereoBox.activeFocus ? "#ff9500" : Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1
                            radius: 6
                        }

                        popup: Popup {
                            y: stereoBox.height + 4
                            width: stereoBox.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 4

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: stereoBox.popup.visible ? stereoBox.delegateModel : null
                                currentIndex: stereoBox.highlightedIndex
                            }

                            background: Rectangle {
                                color: Qt.rgba(0.12, 0.13, 0.18, 0.98)
                                border.color: Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1
                                radius: 8
                            }
                        }

                        delegate: ItemDelegate {
                            width: stereoBox.width
                            contentItem: Text {
                                text: modelData
                                color: highlighted ? "#ff9500" : "white"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: highlighted ? Qt.rgba(255, 149, 0, 0.15) : "transparent"
                                radius: 4
                            }
                        }
                    }
                }
            }

            // ========================================================
            // 2. Subtitles Page
            // ========================================================
            ScrollView {
                id: subScroll
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: subScroll.availableWidth
                    spacing: 14

                    Text {
                        text: "SUBTITLE TRACK"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        font.bold: true
                    }

                    // Disable Subtitles Option
                    Rectangle {
                        id: disableSubOption
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 6
                        property bool isChecked: root.videoSurface ? (root.videoSurface.currentSubtitleTrack === -1) : true
                        color: disableSubMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : (isChecked ? Qt.rgba(255, 149, 0, 0.12) : "transparent")
                        border.color: isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                radius: 9
                                color: "transparent"
                                border.color: disableSubOption.isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.4)
                                border.width: disableSubOption.isChecked ? 2 : 1.5

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8; height: 8; radius: 4
                                    color: "#ff9500"
                                    visible: disableSubOption.isChecked
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Disable Subtitles"
                                color: disableSubOption.isChecked ? "#ff9500" : "white"
                                font.pixelSize: 13
                                font.bold: disableSubOption.isChecked
                            }
                        }

                        MouseArea {
                            id: disableSubMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.videoSurface) root.videoSurface.setSubtitleTrack(-1);
                            }
                        }
                    }

                    // Dynamic Subtitle Tracks List
                    Repeater {
                        model: (root.videoSurface && root.videoSurface.subtitleTracks && root.videoSurface.subtitleTracks.length > 0)
                               ? root.videoSurface.subtitleTracks
                               : []

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 6
                            property bool isChecked: (root.videoSurface ? root.videoSurface.currentSubtitleTrack : 0) === index
                            color: subTrackMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : (isChecked ? Qt.rgba(255, 149, 0, 0.12) : "transparent")
                            border.color: isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "transparent"
                                    border.color: isChecked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.4)
                                    border.width: isChecked ? 2 : 1.5

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8; height: 8; radius: 4
                                        color: "#ff9500"
                                        visible: isChecked
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 30
                                    text: modelData
                                    color: isChecked ? "#ff9500" : "white"
                                    font.pixelSize: 13
                                    font.bold: isChecked
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: subTrackMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.videoSurface) root.videoSurface.setSubtitleTrack(index);
                                }
                            }
                        }
                    }

                    // No subtitles placeholder
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        visible: !root.videoSurface || !root.videoSurface.subtitleTracks || root.videoSurface.subtitleTracks.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: "No embedded subtitle tracks in current media"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.pixelSize: 11
                            font.italic: true
                        }
                    }

                    // Add Subtitle File Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 6
                        color: addSubMouse.containsMouse ? Qt.rgba(255, 149, 0, 0.22) : Qt.rgba(1, 1, 1, 0.08)
                        border.color: addSubMouse.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "+ Add Subtitle File..."
                            color: addSubMouse.containsMouse ? "#ff9500" : "white"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: addSubMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: subtitleDialog.open()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "SUBTITLE SYNCHRONIZATION"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.pixelSize: 11
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: (playerController.subtitleDelayMs > 0 ? "+" : "") + playerController.subtitleDelayMs + " ms"
                            color: playerController.subtitleDelayMs === 0 ? "white" : "#ff9500"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "Monospace"
                        }
                    }

                    Slider {
                        id: subSyncSlider
                        Layout.fillWidth: true
                        from: -5000
                        to: 5000
                        stepSize: 50
                        value: playerController.subtitleDelayMs

                        background: Rectangle {
                            x: subSyncSlider.leftPadding
                            y: subSyncSlider.topPadding + subSyncSlider.availableHeight / 2 - height / 2
                            width: subSyncSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Qt.rgba(1, 1, 1, 0.2)

                            Rectangle {
                                width: subSyncSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#ff9500"
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: subSyncSlider.leftPadding + subSyncSlider.visualPosition * (subSyncSlider.availableWidth - width)
                            y: subSyncSlider.topPadding + subSyncSlider.availableHeight / 2 - height / 2
                            width: 12; height: 12; radius: 6
                            color: "#ff9500"
                            border.color: "white"
                            border.width: 1.5
                        }

                        onMoved: {
                            playerController.subtitleDelayMs = Math.round(subSyncSlider.value);
                            if (root.videoSurface) root.videoSurface.setSubtitleDelay(playerController.subtitleDelayMs);
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 6
                            color: nudgeMinusMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "-50 ms"
                                color: "white"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: nudgeMinusMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    playerController.subtitleDelayMs -= 50;
                                    if (root.videoSurface) root.videoSurface.setSubtitleDelay(playerController.subtitleDelayMs);
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 6
                            color: resetSyncMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Reset (0 ms)"
                                color: resetSyncMouse.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.75)
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: resetSyncMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    playerController.subtitleDelayMs = 0;
                                    if (root.videoSurface) root.videoSurface.setSubtitleDelay(0);
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 6
                            color: nudgePlusMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "+50 ms"
                                color: "white"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                id: nudgePlusMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    playerController.subtitleDelayMs += 50;
                                    if (root.videoSurface) root.videoSurface.setSubtitleDelay(playerController.subtitleDelayMs);
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    Text {
                        text: "SUBTITLE FONT SCALE"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Row {
                        Layout.fillWidth: true
                        spacing: 6

                        property int selectedScale: 1 // 0: Small, 1: Normal, 2: Large, 3: Huge

                        Repeater {
                            model: ["Small (80%)", "Normal (100%)", "Large (120%)", "Huge (150%)"]
                            delegate: Rectangle {
                                width: (subScroll.availableWidth - 18) / 4
                                height: 30
                                radius: 6
                                property bool isCur: parent.selectedScale === index
                                color: isCur ? "#ff9500" : (scaleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
                                border.color: isCur ? "#ff9500" : Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.split(" ")[0]
                                    color: isCur ? "#111111" : "white"
                                    font.pixelSize: 11
                                    font.bold: isCur
                                }

                                MouseArea {
                                    id: scaleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: parent.parent.selectedScale = index
                                }
                            }
                        }
                    }
                }
            }

            // ========================================================
            // 3. Bezier Equalizer Page
            // ========================================================
            ScrollView {
                id: eqScroll
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: eqScroll.availableWidth
                    spacing: 12

                    RowLayout {
                        Text {
                            text: "BEZIER CURVE EQUALIZER"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }
                        Switch {
                            id: eqSwitch
                            checked: true
                            indicator: Rectangle {
                                implicitWidth: 36
                                implicitHeight: 20
                                x: eqSwitch.leftPadding
                                y: parent.height / 2 - height / 2
                                radius: 10
                                color: eqSwitch.checked ? "#ff9500" : Qt.rgba(1, 1, 1, 0.2)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    x: eqSwitch.checked ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "white"
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }
                            }
                        }
                    }

                    ComboBox {
                        id: presetBox
                        Layout.fillWidth: true
                        model: ["Flat", "Bass Boost", "Vocal Clarity", "Rock"]

                        contentItem: Text {
                            text: presetBox.displayText
                            font.pixelSize: 13
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 12
                        }

                        background: Rectangle {
                            implicitHeight: 38
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.color: presetBox.activeFocus ? "#ff9500" : Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1
                            radius: 6
                        }

                        popup: Popup {
                            y: presetBox.height + 4
                            width: presetBox.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 4

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: presetBox.popup.visible ? presetBox.delegateModel : null
                                currentIndex: presetBox.highlightedIndex
                            }

                            background: Rectangle {
                                color: Qt.rgba(0.12, 0.13, 0.18, 0.98)
                                border.color: Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1
                                radius: 8
                            }
                        }

                        delegate: ItemDelegate {
                            width: presetBox.width
                            contentItem: Text {
                                text: modelData
                                color: highlighted ? "#ff9500" : "white"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: highlighted ? Qt.rgba(255, 149, 0, 0.15) : "transparent"
                                radius: 4
                            }
                        }

                        onActivated: bezierEq.setPreset(currentText)
                    }

                    // Bezier Curve Canvas
                    BezierEqualizer {
                        id: bezierEq
                        Layout.fillWidth: true
                        Layout.preferredHeight: 240
                        enabled: eqSwitch.checked
                        opacity: eqSwitch.checked ? 1.0 : 0.4
                        Behavior on opacity { NumberAnimation { duration: 180 } }

                        onBandGainChanged: {
                            if (root.videoSurface) {
                                root.videoSurface.setEqualizerBand(bandIndex, gainDb);
                            }
                        }
                    }

                    Text {
                        text: "Tip: Drag control nodes to shape response. Double-click to zero."
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // ========================================================
            // 4. Video Filters Page
            // ========================================================
            ScrollView {
                id: videoScroll
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: videoScroll.availableWidth
                    spacing: 12

                    Text {
                        text: "COLOR ADJUSTMENTS"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        font.bold: true
                    }

                    // Brightness (libvlc_adjust_Brightness = 2)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "Brightness"; color: "white"; Layout.fillWidth: true; font.pixelSize: 12 }
                        Text { text: bSlider.value.toFixed(2); color: "#ff9500"; font.pixelSize: 11; font.family: "Monospace"; font.bold: true; Layout.preferredWidth: 32 }
                        Slider {
                            id: bSlider
                            from: 0.2; to: 2.0
                            value: root.videoSurface ? root.videoSurface.brightness : 1.0
                            Layout.preferredWidth: 160
                            hoverEnabled: true

                            background: Rectangle {
                                x: bSlider.leftPadding
                                y: bSlider.topPadding + bSlider.availableHeight / 2 - height / 2
                                width: bSlider.availableWidth
                                height: (bSlider.hovered || bSlider.pressed) ? 5 : 4
                                radius: height / 2
                                color: Qt.rgba(1, 1, 1, 0.18)

                                Rectangle {
                                    width: bSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#ff9500"
                                    radius: parent.radius
                                }
                            }

                            handle: Rectangle {
                                x: bSlider.leftPadding + bSlider.visualPosition * (bSlider.availableWidth - width)
                                y: bSlider.topPadding + bSlider.availableHeight / 2 - height / 2
                                width: (bSlider.hovered || bSlider.pressed) ? 14 : 11
                                height: width
                                radius: width / 2
                                color: "#ff9500"
                                border.color: "white"
                                border.width: 1.5
                            }

                            onMoved: {
                                if (root.videoSurface) root.videoSurface.setBrightness(bSlider.value);
                            }
                            onPressedChanged: {
                                if (!pressed && root.videoSurface) {
                                    root.videoSurface.setBrightness(bSlider.value);
                                }
                            }
                        }
                    }

                    // Contrast (libvlc_adjust_Contrast = 1)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "Contrast"; color: "white"; Layout.fillWidth: true; font.pixelSize: 12 }
                        Text { text: cSlider.value.toFixed(2); color: "#ff9500"; font.pixelSize: 11; font.family: "Monospace"; font.bold: true; Layout.preferredWidth: 32 }
                        Slider {
                            id: cSlider
                            from: 0.0; to: 2.0
                            value: root.videoSurface ? root.videoSurface.contrast : 1.0
                            Layout.preferredWidth: 160
                            hoverEnabled: true

                            background: Rectangle {
                                x: cSlider.leftPadding
                                y: cSlider.topPadding + cSlider.availableHeight / 2 - height / 2
                                width: cSlider.availableWidth
                                height: (cSlider.hovered || cSlider.pressed) ? 5 : 4
                                radius: height / 2
                                color: Qt.rgba(1, 1, 1, 0.18)

                                Rectangle {
                                    width: cSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#ff9500"
                                    radius: parent.radius
                                }
                            }

                            handle: Rectangle {
                                x: cSlider.leftPadding + cSlider.visualPosition * (cSlider.availableWidth - width)
                                y: cSlider.topPadding + cSlider.availableHeight / 2 - height / 2
                                width: (cSlider.hovered || cSlider.pressed) ? 14 : 11
                                height: width
                                radius: width / 2
                                color: "#ff9500"
                                border.color: "white"
                                border.width: 1.5
                            }

                            onMoved: {
                                if (root.videoSurface) root.videoSurface.setContrast(cSlider.value);
                            }
                            onPressedChanged: {
                                if (!pressed && root.videoSurface) root.videoSurface.setContrast(cSlider.value);
                            }
                        }
                    }

                    // Saturation (libvlc_adjust_Saturation = 4)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "Saturation"; color: "white"; Layout.fillWidth: true; font.pixelSize: 12 }
                        Text { text: sSlider.value.toFixed(2); color: "#ff9500"; font.pixelSize: 11; font.family: "Monospace"; font.bold: true; Layout.preferredWidth: 32 }
                        Slider {
                            id: sSlider
                            from: 0.0; to: 3.0
                            value: root.videoSurface ? root.videoSurface.saturation : 1.0
                            Layout.preferredWidth: 160
                            hoverEnabled: true

                            background: Rectangle {
                                x: sSlider.leftPadding
                                y: sSlider.topPadding + sSlider.availableHeight / 2 - height / 2
                                width: sSlider.availableWidth
                                height: (sSlider.hovered || sSlider.pressed) ? 5 : 4
                                radius: height / 2
                                color: Qt.rgba(1, 1, 1, 0.18)

                                Rectangle {
                                    width: sSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#ff9500"
                                    radius: parent.radius
                                }
                            }

                            handle: Rectangle {
                                x: sSlider.leftPadding + sSlider.visualPosition * (sSlider.availableWidth - width)
                                y: sSlider.topPadding + sSlider.availableHeight / 2 - height / 2
                                width: (sSlider.hovered || sSlider.pressed) ? 14 : 11
                                height: width
                                radius: width / 2
                                color: "#ff9500"
                                border.color: "white"
                                border.width: 1.5
                            }

                            onMoved: {
                                if (root.videoSurface) root.videoSurface.setSaturation(sSlider.value);
                            }
                            onPressedChanged: {
                                if (!pressed && root.videoSurface) root.videoSurface.setSaturation(sSlider.value);
                            }
                        }
                    }

                    // Gamma (libvlc_adjust_Gamma = 5)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "Gamma"; color: "white"; Layout.fillWidth: true; font.pixelSize: 12 }
                        Text { text: gSlider.value.toFixed(2); color: "#ff9500"; font.pixelSize: 11; font.family: "Monospace"; font.bold: true; Layout.preferredWidth: 32 }
                        Slider {
                            id: gSlider
                            from: 0.5; to: 2.0
                            value: root.videoSurface ? root.videoSurface.gamma : 1.0
                            Layout.preferredWidth: 160
                            hoverEnabled: true

                            background: Rectangle {
                                x: gSlider.leftPadding
                                y: gSlider.topPadding + gSlider.availableHeight / 2 - height / 2
                                width: gSlider.availableWidth
                                height: (gSlider.hovered || gSlider.pressed) ? 5 : 4
                                radius: height / 2
                                color: Qt.rgba(1, 1, 1, 0.18)

                                Rectangle {
                                    width: gSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#ff9500"
                                    radius: parent.radius
                                }
                            }

                            handle: Rectangle {
                                x: gSlider.leftPadding + gSlider.visualPosition * (gSlider.availableWidth - width)
                                y: gSlider.topPadding + gSlider.availableHeight / 2 - height / 2
                                width: (gSlider.hovered || gSlider.pressed) ? 14 : 11
                                height: width
                                radius: width / 2
                                color: "#ff9500"
                                border.color: "white"
                                border.width: 1.5
                            }

                            onMoved: {
                                if (root.videoSurface) root.videoSurface.setGamma(gSlider.value);
                            }
                            onPressedChanged: {
                                if (!pressed && root.videoSurface) root.videoSurface.setGamma(gSlider.value);
                            }
                        }
                    }

                    // Reset Adjustments Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        Layout.topMargin: 4
                        radius: 6
                        color: resetAdjustMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Reset Color Adjustments"
                            color: resetAdjustMouse.containsMouse ? "#ff9500" : Qt.rgba(1, 1, 1, 0.75)
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: resetAdjustMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                bSlider.value = 1.0;
                                cSlider.value = 1.0;
                                sSlider.value = 1.0;
                                gSlider.value = 1.0;
                                if (root.videoSurface) {
                                    root.videoSurface.setBrightness(1.0);
                                    root.videoSurface.setContrast(1.0);
                                    root.videoSurface.setSaturation(1.0);
                                    root.videoSurface.setGamma(1.0);
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    Text {
                        text: "ASPECT RATIO & CROP"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        font.bold: true
                    }

                    ComboBox {
                        id: aspectBox
                        Layout.fillWidth: true
                        model: ["Default (Auto)", "16:9", "4:3", "2.35:1 (CinemaScope)", "2.39:1", "Fill Screen", "Stretch"]

                        contentItem: Text {
                            text: aspectBox.displayText
                            font.pixelSize: 13
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 12
                        }

                        background: Rectangle {
                            implicitHeight: 38
                            color: Qt.rgba(1, 1, 0, 0.08)
                            border.color: aspectBox.activeFocus ? "#ff9500" : Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1
                            radius: 6
                        }

                        popup: Popup {
                            y: aspectBox.height + 4
                            width: aspectBox.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 4

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: aspectBox.popup.visible ? aspectBox.delegateModel : null
                                currentIndex: aspectBox.highlightedIndex
                            }

                            background: Rectangle {
                                color: Qt.rgba(0.12, 0.13, 0.18, 0.98)
                                border.color: Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1
                                radius: 8
                            }
                        }

                        delegate: ItemDelegate {
                            width: aspectBox.width
                            contentItem: Text {
                                text: modelData
                                color: highlighted ? "#ff9500" : "white"
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: highlighted ? Qt.rgba(255, 149, 0, 0.15) : "transparent"
                                radius: 4
                            }
                        }

                        onActivated: function(index) {
                            if (root.videoSurface) {
                                if (index === 0) {
                                    root.videoSurface.fillMode = 0; // Fit
                                    root.videoSurface.setCustomAspect(0.0);
                                } else if (index === 1) {
                                    root.videoSurface.fillMode = 0;
                                    root.videoSurface.setCustomAspect(16.0 / 9.0);
                                } else if (index === 2) {
                                    root.videoSurface.fillMode = 0;
                                    root.videoSurface.setCustomAspect(4.0 / 3.0);
                                } else if (index === 3) {
                                    root.videoSurface.fillMode = 0;
                                    root.videoSurface.setCustomAspect(2.35);
                                } else if (index === 4) {
                                    root.videoSurface.fillMode = 0;
                                    root.videoSurface.setCustomAspect(2.39);
                                } else if (index === 5) {
                                    root.videoSurface.fillMode = 1; // Fill Screen
                                    root.videoSurface.setCustomAspect(0.0);
                                } else if (index === 6) {
                                    root.videoSurface.fillMode = 2; // Stretch
                                    root.videoSurface.setCustomAspect(0.0);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}
