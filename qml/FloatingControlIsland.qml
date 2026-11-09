import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property bool isPlaying: false
    property real progress: 0.0 // 0.0 to 1.0
    property real totalDurationMs: 0
    property string currentTime: "00:00:00"
    property string remainingTime: "-00:00:00"
    property string totalDurationStr: "00:00:00"
    property bool showTotalTime: false
    property real volumeLevel: 0.85
    property bool isMuted: false
    property bool isFullscreen: false
    property real playbackRate: 1.0
    property int fillMode: 0 // 0 = Fit, 1 = Fill, 2 = Stretch
    property bool hasSubtitles: false
    property bool areSubtitlesEnabled: false
    property string currentDeviceType: "headphones"
    property string currentDeviceName: "Headphones"
    property bool isAudioOutputMenuOpen: false

    property bool containsMouse: islandMouseTracker.containsMouse

    signal playPauseClicked()
    signal seekRequested(real position)
    signal volumeChanged(real volume)
    signal muteToggled()
    signal fullscreenToggled()
    signal openDrawerClicked()
    signal pipToggled()
    signal ccClicked()
    signal openPlaylistClicked()
    signal previousClicked()
    signal nextClicked()
    signal skipBackwardClicked()
    signal skipForwardClicked()
    signal speedClicked()
    signal aspectRatioClicked()
    signal audioTrackClicked()
    signal openAudioOutputClicked()
    signal activityHappened()

    implicitHeight: 74
    radius: 0

    // Solid Docked Bottom Bar Panel (Zero Dead Space Underneath)
    color: Qt.rgba(0.05, 0.06, 0.08, 0.96)

    // Subtle Top Border Separator Line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(255, 255, 255, 0.12)
    }

    // Island-wide hover tracker to prevent auto-hide when user mouse is over controls
    MouseArea {
        id: islandMouseTracker
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: root.activityHappened()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 4
        anchors.bottomMargin: 6
        spacing: 2

        // ========================================================
        // TIER 1: Full-Width Timeline Scrubber (Screen-Wide Precision)
        // ========================================================
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            // Floating Timestamp Hover Preview Bubble above Seekbar
            Item {
                id: hoverPreview
                anchors.bottom: parent.top
                anchors.bottomMargin: 6
                width: timeLabel.implicitWidth + 16
                height: 24
                visible: (seekSlider.isHovered || seekSlider.pressed) && root.totalDurationMs > 0
                opacity: visible ? 1.0 : 0.0

                x: Math.max(0, Math.min(parent.width - width, (seekSlider.pressed ? seekSlider.visualPosition * seekSlider.width : seekSlider.hoverX) - width / 2))

                Behavior on opacity { NumberAnimation { duration: 120 } }

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: Qt.rgba(0.08, 0.09, 0.12, 0.96)
                    border.color: Qt.rgba(255, 255, 255, 0.22)
                    border.width: 1

                    Text {
                        id: timeLabel
                        anchors.centerIn: parent
                        text: {
                            var pos = seekSlider.pressed ? seekSlider.value : seekSlider.hoverPosition;
                            var ms = Math.round(pos * root.totalDurationMs);
                            var s = Math.floor(ms / 1000);
                            var h = Math.floor(s / 3600);
                            var m = Math.floor((s % 3600) / 60);
                            var sec = s % 60;
                            if (h > 0)
                                return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
                            else
                                return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
                        }
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Monospace"
                        color: "#ff9500"
                    }
                }

                // Downward pointer arrow
                Canvas {
                    anchors.top: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: -1
                    width: 8
                    height: 4
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = Qt.rgba(0.08, 0.09, 0.12, 0.96);
                        ctx.beginPath();
                        ctx.moveTo(0, 0);
                        ctx.lineTo(8, 0);
                        ctx.lineTo(4, 4);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            // Scrubber Slider
            Slider {
                id: seekSlider
                anchors.fill: parent
                from: 0.0
                to: 1.0
                hoverEnabled: true

                property real hoverX: 0
                property real hoverPosition: 0.0
                property bool isHovered: false

                value: pressed ? value : root.progress

                MouseArea {
                    id: seekHoverTracker
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton

                    onPositionChanged: function(mouse) {
                        seekSlider.hoverX = mouse.x;
                        seekSlider.hoverPosition = Math.max(0.0, Math.min(1.0, mouse.x / seekSlider.width));
                        root.activityHappened();
                    }
                    onEntered: seekSlider.isHovered = true
                    onExited: seekSlider.isHovered = false
                }

                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + (seekSlider.availableHeight - height) / 2
                    width: seekSlider.availableWidth
                    implicitHeight: (seekSlider.hovered || seekSlider.pressed) ? 7 : 4
                    height: implicitHeight
                    radius: height / 2
                    color: Qt.rgba(255, 255, 255, 0.22)

                    Behavior on implicitHeight { NumberAnimation { duration: 120 } }

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        color: "#ff9500"
                        radius: parent.radius
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + (seekSlider.availableHeight - height) / 2
                    implicitWidth: (seekSlider.hovered || seekSlider.pressed) ? 16 : 12
                    implicitHeight: implicitWidth
                    radius: implicitWidth / 2
                    color: "#ffffff"
                    border.color: "#ff9500"
                    border.width: 2.2

                    Behavior on implicitWidth { NumberAnimation { duration: 120 } }
                }

                onMoved: {
                    root.seekRequested(seekSlider.value);
                    root.activityHappened();
                }

                onPressedChanged: {
                    if (!pressed) {
                        root.seekRequested(seekSlider.value);
                    }
                    root.activityHappened();
                }
            }
        }

        // ========================================================
        // TIER 2: Controls Row
        // ========================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            // ----------------------------------------------------
            // Left Group: Playback Controls + Timestamps
            // ----------------------------------------------------
            Row {
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                // 1. Previous Track
                Rectangle {
                    width: 30; height: 28; radius: 6
                    color: prevMouse.pressed ? Qt.rgba(255, 255, 255, 0.18) : (prevMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: prevCanvas
                        anchors.centerIn: parent
                        width: 13; height: 13
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = prevMouse.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85);
                            ctx.fillRect(1.5, 2.0, 1.8, 9);
                            ctx.beginPath();
                            ctx.moveTo(10.5, 2.0); ctx.lineTo(4.0, 6.5); ctx.lineTo(10.5, 11.0);
                            ctx.closePath(); ctx.fill();
                        }
                        Connections {
                            target: prevMouse
                            function onContainsMouseChanged() { prevCanvas.requestPaint(); }
                        }
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.previousClicked(); root.activityHappened(); }
                    }
                    ModernToolTip { visible: prevMouse.containsMouse; text: "Previous Track" }
                }

                // 2. Skip -10s Button
                Rectangle {
                    width: 32; height: 28; radius: 6
                    color: skipBackMouse.pressed ? Qt.rgba(255, 255, 255, 0.18) : (skipBackMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 1
                        Text {
                            text: "<<"
                            font.pixelSize: 10
                            font.bold: true
                            color: skipBackMouse.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85)
                        }
                        Text {
                            text: "10"
                            font.pixelSize: 9
                            font.bold: true
                            color: skipBackMouse.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85)
                        }
                    }

                    MouseArea {
                        id: skipBackMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.skipBackwardClicked(); root.activityHappened(); }
                    }
                    ModernToolTip { visible: skipBackMouse.containsMouse; text: "Skip -10s (Left Arrow)" }
                }

                // 3. Play / Pause Button (Hero Action: Refined Amber Circle)
                Item {
                    width: 42
                    height: 36

                    Rectangle {
                        id: playBtn
                        width: 34; height: 34; radius: 17
                        anchors.centerIn: parent
                        color: playArea.pressed ? "#e68500" : (playArea.containsMouse ? "#ffa522" : "#ff9500")
                        scale: playArea.containsMouse ? 1.05 : 1.0
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Canvas {
                            id: playIconCanvas
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: root.isPlaying ? 0 : 1.0
                            width: 14; height: 14

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = "#121212";

                                if (root.isPlaying) {
                                    ctx.beginPath();
                                    ctx.rect(2.0, 1.5, 3.2, 11);
                                    ctx.rect(8.8, 1.5, 3.2, 11);
                                    ctx.fill();
                                } else {
                                    ctx.beginPath();
                                    ctx.moveTo(2.5, 1.0);
                                    ctx.lineTo(12.5, 7.0);
                                    ctx.lineTo(2.5, 13.0);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                            }

                            Connections {
                                target: root
                                function onIsPlayingChanged() { playIconCanvas.requestPaint(); }
                            }
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.playPauseClicked(); root.activityHappened(); }
                        }
                    }
                    ModernToolTip { visible: playArea.containsMouse; text: root.isPlaying ? "Pause (Space)" : "Play (Space)" }
                }

                // 4. Skip +10s Button
                Rectangle {
                    width: 32; height: 28; radius: 6
                    color: skipFwdMouse.pressed ? Qt.rgba(255, 255, 255, 0.18) : (skipFwdMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 1
                        Text {
                            text: "10"
                            font.pixelSize: 9
                            font.bold: true
                            color: skipFwdMouse.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85)
                        }
                        Text {
                            text: ">>"
                            font.pixelSize: 10
                            font.bold: true
                            color: skipFwdMouse.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85)
                        }
                    }

                    MouseArea {
                        id: skipFwdMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.skipForwardClicked(); root.activityHappened(); }
                    }
                    ModernToolTip { visible: skipFwdMouse.containsMouse; text: "Skip +10s (Right Arrow)" }
                }

                // 5. Next Track
                Rectangle {
                    width: 30; height: 28; radius: 6
                    color: nextMouse.pressed ? Qt.rgba(255, 255, 255, 0.18) : (nextMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: nextCanvas
                        anchors.centerIn: parent
                        width: 13; height: 13
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = nextMouse.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85);
                            ctx.beginPath();
                            ctx.moveTo(2.5, 2.0); ctx.lineTo(9.0, 6.5); ctx.lineTo(2.5, 11.0);
                            ctx.closePath(); ctx.fill();
                            ctx.fillRect(9.8, 2.0, 1.8, 9);
                        }
                        Connections {
                            target: nextMouse
                            function onContainsMouseChanged() { nextCanvas.requestPaint(); }
                        }
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.nextClicked(); root.activityHappened(); }
                    }
                    ModernToolTip { visible: nextMouse.containsMouse; text: "Next Track" }
                }

                // Breathing Margin between controls and timestamps
                Item { width: 8; height: 1 }

                // Timestamps (Elapsed / Total or Countdown) with generous, readable typography
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: root.currentTime
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        font.family: "Monospace"
                    }

                    Text {
                        text: "/"
                        color: Qt.rgba(255, 255, 255, 0.35)
                        font.pixelSize: 13
                        font.weight: Font.Normal
                    }

                    Rectangle {
                        width: remTimeText.implicitWidth + 10
                        height: 22
                        radius: 4
                        color: remTimeArea.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: remTimeText
                            anchors.centerIn: parent
                            text: root.showTotalTime ? root.totalDurationStr : root.remainingTime
                            color: Qt.rgba(255, 255, 255, 0.75)
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: "Monospace"
                        }

                        MouseArea {
                            id: remTimeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.showTotalTime = !root.showTotalTime;
                                root.activityHappened();
                            }
                        }
                        ModernToolTip {
                            visible: remTimeArea.containsMouse
                            text: root.showTotalTime ? "Switch to Countdown Time" : "Switch to Total Duration"
                        }
                    }
                }
            }

            // Flexible Spacer
            Item { Layout.fillWidth: true }

            // ----------------------------------------------------
            // Right Group: Dedicated Volume Pod + Unified Secondary Controls
            // ----------------------------------------------------
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                // ========================================================
                // UNIFIED VOLUME & AUDIO OUTPUT POD
                // ========================================================
                Rectangle {
                    id: volumePod
                    height: 28
                    width: 156
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(255, 255, 255, 0.08)
                    border.color: (volSlider.hovered || volSlider.pressed || speakerMuteArea.containsMouse || outputMouse.containsMouse || root.isAudioOutputMenuOpen) ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 3

                        // Speaker Icon Button inside Pod
                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 4
                            color: speakerMuteArea.pressed ? Qt.rgba(255, 255, 255, 0.15) : (speakerMuteArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")

                            Canvas {
                                id: speakerCanvas
                                anchors.centerIn: parent
                                width: 13; height: 13

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var activeColor = root.isMuted ? "#ff453a" : (speakerMuteArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85));
                                    ctx.fillStyle = activeColor;
                                    ctx.strokeStyle = activeColor;
                                    ctx.lineWidth = 1.3;
                                    ctx.lineCap = "round";

                                    // Speaker Cone
                                    ctx.beginPath();
                                    ctx.moveTo(1.5, 4.5); ctx.lineTo(3.8, 4.5); ctx.lineTo(6.8, 2.0);
                                    ctx.lineTo(6.8, 11.0); ctx.lineTo(3.8, 8.5); ctx.lineTo(1.5, 8.5);
                                    ctx.closePath(); ctx.fill();

                                    if (root.isMuted || root.volumeLevel <= 0.01) {
                                        // Mute diagonal line
                                        ctx.beginPath();
                                        ctx.moveTo(8.5, 4.0); ctx.lineTo(11.5, 9.0);
                                        ctx.moveTo(11.5, 4.0); ctx.lineTo(8.5, 9.0);
                                        ctx.stroke();
                                    } else if (root.volumeLevel > 0.5) {
                                        ctx.beginPath();
                                        ctx.arc(6.5, 6.5, 3.0, -Math.PI / 3.0, Math.PI / 3.0, false);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.arc(6.5, 6.5, 5.2, -Math.PI / 3.0, Math.PI / 3.0, false);
                                        ctx.stroke();
                                    } else {
                                        ctx.beginPath();
                                        ctx.arc(6.5, 6.5, 3.0, -Math.PI / 3.0, Math.PI / 3.0, false);
                                        ctx.stroke();
                                    }
                                }

                                Connections {
                                    target: root
                                    function onVolumeLevelChanged() { speakerCanvas.requestPaint(); }
                                    function onIsMutedChanged() { speakerCanvas.requestPaint(); }
                                }
                                Connections {
                                    target: speakerMuteArea
                                    function onContainsMouseChanged() { speakerCanvas.requestPaint(); }
                                }
                            }

                            MouseArea {
                                id: speakerMuteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.muteToggled();
                                    root.activityHappened();
                                }
                            }
                            ModernToolTip {
                                visible: speakerMuteArea.containsMouse
                                text: root.isMuted ? "Unmute (M)" : "Mute (M)"
                            }
                        }

                        // Embedded Volume Slider inside Pod (clean, precisely aligned bounds)
                        Slider {
                            id: volSlider
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            from: 0.0
                            to: 1.0
                            stepSize: 0.01
                            hoverEnabled: true

                            value: pressed ? value : (root.isMuted ? 0.0 : Math.min(1.0, root.volumeLevel))

                            background: Rectangle {
                                x: volSlider.leftPadding
                                y: volSlider.topPadding + (volSlider.availableHeight - height) / 2
                                width: volSlider.availableWidth
                                implicitHeight: 4
                                height: implicitHeight
                                radius: 2
                                color: Qt.rgba(255, 255, 255, 0.20)

                                // Active Fill Bar
                                Rectangle {
                                    width: volSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: root.isMuted ? Qt.rgba(255, 255, 255, 0.35) : "#ff9500"
                                    radius: parent.radius
                                }
                            }

                            handle: Rectangle {
                                x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                                y: volSlider.topPadding + (volSlider.availableHeight - height) / 2
                                implicitWidth: (volSlider.hovered || volSlider.pressed) ? 12 : 10
                                implicitHeight: implicitWidth
                                radius: implicitWidth / 2
                                color: "#ffffff"
                                border.color: root.isMuted ? Qt.rgba(255, 255, 255, 0.5) : "#ff9500"
                                border.width: 1.8

                                Behavior on implicitWidth { NumberAnimation { duration: 100 } }
                            }

                            onMoved: {
                                root.volumeChanged(volSlider.value);
                                root.activityHappened();
                            }
                            onPressedChanged: {
                                if (!pressed) root.volumeChanged(volSlider.value);
                                root.activityHappened();
                            }
                        }

                        // Dynamic Audio Output Hardware Selector Trigger
                        Rectangle {
                            id: outputDeviceBtn
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 4
                            color: outputMouse.pressed 
                                   ? Qt.rgba(255, 255, 255, 0.22) 
                                   : (outputMouse.containsMouse || root.isAudioOutputMenuOpen 
                                      ? Qt.rgba(255, 255, 255, 0.14) 
                                      : "transparent")
                            border.color: root.isAudioOutputMenuOpen 
                                          ? "#ff9500" 
                                          : (outputMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : "transparent")
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Canvas {
                                id: devIconCanvas
                                anchors.centerIn: parent
                                width: 14
                                height: 14

                                property color iconColor: root.isAudioOutputMenuOpen 
                                                          ? "#ff9500" 
                                                          : (outputMouse.containsMouse ? "#ffffff" : Qt.rgba(255, 255, 255, 0.85))

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = iconColor;
                                    ctx.fillStyle = iconColor;
                                    ctx.lineWidth = 1.25;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";

                                    if (root.currentDeviceType === "headphones") {
                                        // Overhead arc headband
                                        ctx.beginPath();
                                        ctx.arc(7.0, 7.5, 5.2, Math.PI, 2 * Math.PI, false);
                                        ctx.stroke();
                                        // Left earcup
                                        ctx.beginPath();
                                        ctx.roundedRect(1.2, 7.0, 2.8, 5.5, 1.2, 1.2);
                                        ctx.fill();
                                        // Right earcup
                                        ctx.beginPath();
                                        ctx.roundedRect(10.0, 7.0, 2.8, 5.5, 1.2, 1.2);
                                        ctx.fill();
                                    } else if (root.currentDeviceType === "bluetooth") {
                                        // Bluetooth geometric rune
                                        ctx.beginPath();
                                        ctx.moveTo(7.0, 1.5); ctx.lineTo(7.0, 12.5);
                                        ctx.moveTo(7.0, 1.5); ctx.lineTo(11.0, 4.5); ctx.lineTo(4.0, 9.5);
                                        ctx.moveTo(7.0, 12.5); ctx.lineTo(11.0, 9.5); ctx.lineTo(4.0, 4.5);
                                        ctx.stroke();
                                    } else if (root.currentDeviceType === "hdmi") {
                                        // Display monitor
                                        ctx.strokeRect(1.5, 2.0, 11.0, 7.5);
                                        ctx.beginPath();
                                        ctx.moveTo(7.0, 9.5); ctx.lineTo(7.0, 12.0);
                                        ctx.moveTo(4.5, 12.0); ctx.lineTo(9.5, 12.0);
                                        ctx.stroke();
                                    } else {
                                        // Speaker Driver
                                        ctx.beginPath();
                                        ctx.moveTo(1.8, 4.5); ctx.lineTo(4.5, 4.5); ctx.lineTo(7.8, 2.0);
                                        ctx.lineTo(7.8, 12.0); ctx.lineTo(4.5, 9.5); ctx.lineTo(1.8, 9.5);
                                        ctx.closePath();
                                        ctx.fill();
                                        // Waves
                                        ctx.beginPath();
                                        ctx.arc(7.5, 7.0, 3.5, -Math.PI / 3.0, Math.PI / 3.0, false);
                                        ctx.stroke();
                                    }
                                }

                                Connections {
                                    target: root
                                    function onCurrentDeviceTypeChanged() { devIconCanvas.requestPaint(); }
                                    function onIsAudioOutputMenuOpenChanged() { devIconCanvas.requestPaint(); }
                                }
                                Connections {
                                    target: outputMouse
                                    function onContainsMouseChanged() { devIconCanvas.requestPaint(); }
                                }
                            }

                            MouseArea {
                                id: outputMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.openAudioOutputClicked();
                                    root.activityHappened();
                                }
                            }

                            ModernToolTip {
                                visible: outputMouse.containsMouse
                                text: "Audio Output: " + root.currentDeviceName + " (Click to switch)"
                            }
                        }
                    }
                }

                // Breathing Margin between volume pod and secondary controls
                Item { width: 2; height: 1 }

                // ========================================================
                // UNIFIED SECONDARY CONTROLS (Identical Interactive Chip Buttons)
                // Height: 28, Radius: 6, Consistent fill, border, and active amber
                // ========================================================

                // 1. Playback Speed Button
                Rectangle {
                    width: 44; height: 28; radius: 6
                    color: speedMouse.pressed ? Qt.rgba(255, 255, 255, 0.20) : (speedMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : ((root.playbackRate !== 1.0) ? Qt.rgba(255, 149, 0, 0.20) : Qt.rgba(255, 255, 255, 0.08)))
                    border.color: (root.playbackRate !== 1.0) ? Qt.rgba(255, 149, 0, 0.60) : (speedMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12))
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.playbackRate.toFixed(root.playbackRate % 1 === 0 ? 1 : 2) + "x"
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Monospace"
                        color: (root.playbackRate !== 1.0) ? "#ff9500" : (speedMouse.containsMouse ? "#ffffff" : Qt.rgba(255, 255, 255, 0.85))
                    }

                    MouseArea {
                        id: speedMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.speedClicked(); root.activityHappened(); }
                    }
                    ModernToolTip {
                        visible: speedMouse.containsMouse
                        text: "Playback Speed (" + root.playbackRate.toFixed(2) + "x)"
                    }
                }

                // 2. Aspect Ratio / Scaling Button (Replaced ambiguous 'STR' text with sleek vector icon)
                Rectangle {
                    width: 36; height: 28; radius: 6
                    color: aspectMouse.pressed ? Qt.rgba(255, 255, 255, 0.20) : (aspectMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : ((root.fillMode !== 0) ? Qt.rgba(255, 149, 0, 0.20) : Qt.rgba(255, 255, 255, 0.08)))
                    border.color: (root.fillMode !== 0) ? Qt.rgba(255, 149, 0, 0.60) : (aspectMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12))
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: aspectCanvas
                        anchors.centerIn: parent
                        width: 16; height: 16
                        property color iconColor: (root.fillMode !== 0) ? "#ff9500" : (aspectMouse.containsMouse ? "#ffffff" : Qt.rgba(255, 255, 255, 0.85))

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = iconColor;
                            ctx.fillStyle = iconColor;
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";

                            // Screen Aspect Ratio Outer Display Frame
                            ctx.strokeRect(1.5, 3.0, 13.0, 10.0);

                            if (root.fillMode === 0) {
                                // Fit (Original): Centered proportional video frame
                                ctx.strokeRect(3.8, 5.2, 8.4, 5.6);
                            } else if (root.fillMode === 1) {
                                // Fill (Crop): Outward corner arrows expanding to full bleed
                                ctx.beginPath();
                                ctx.moveTo(4.5, 6.0); ctx.lineTo(2.0, 3.5);
                                ctx.moveTo(11.5, 6.0); ctx.lineTo(14.0, 3.5);
                                ctx.moveTo(4.5, 10.0); ctx.lineTo(2.0, 12.5);
                                ctx.moveTo(11.5, 10.0); ctx.lineTo(14.0, 12.5);
                                ctx.stroke();
                            } else {
                                // Stretch (Anamorphic): Horizontal double-headed stretch arrow inside screen
                                ctx.beginPath();
                                ctx.moveTo(4.0, 8.0); ctx.lineTo(12.0, 8.0);
                                ctx.moveTo(6.0, 6.0); ctx.lineTo(4.0, 8.0); ctx.lineTo(6.0, 10.0);
                                ctx.moveTo(10.0, 6.0); ctx.lineTo(12.0, 8.0); ctx.lineTo(10.0, 10.0);
                                ctx.stroke();
                            }
                        }

                        Connections {
                            target: root
                            function onFillModeChanged() { aspectCanvas.requestPaint(); }
                        }
                        Connections {
                            target: aspectMouse
                            function onContainsMouseChanged() { aspectCanvas.requestPaint(); }
                        }
                    }

                    MouseArea {
                        id: aspectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.aspectRatioClicked(); root.activityHappened(); }
                    }
                    ModernToolTip {
                        visible: aspectMouse.containsMouse
                        text: "Aspect Ratio: " + (root.fillMode === 0 ? "Original (Fit)" : (root.fillMode === 1 ? "Crop to Fill Screen" : "Stretch to Window")) + " (Click to cycle)"
                    }
                }

                // 3. Subtitles (CC) Button
                Rectangle {
                    width: 36; height: 28; radius: 6
                    opacity: root.hasSubtitles ? 1.0 : 0.40
                    color: ccArea.pressed ? Qt.rgba(255, 255, 255, 0.20) : ((root.hasSubtitles && root.areSubtitlesEnabled) ? Qt.rgba(255, 149, 0, 0.20) : (ccArea.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08)))
                    border.color: (root.hasSubtitles && root.areSubtitlesEnabled) ? Qt.rgba(255, 149, 0, 0.60) : (ccArea.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12))
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "CC"
                        font.pixelSize: 11
                        font.bold: true
                        color: (root.hasSubtitles && root.areSubtitlesEnabled) ? "#ff9500" : (ccArea.containsMouse ? "#ffffff" : Qt.rgba(255, 255, 255, 0.85))
                    }

                    MouseArea {
                        id: ccArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.ccClicked(); root.activityHappened(); }
                    }
                    ModernToolTip {
                        visible: ccArea.containsMouse
                        text: root.hasSubtitles ? (root.areSubtitlesEnabled ? "Subtitles: On (Click to Disable)" : "Subtitles: Off (Click to Enable)") : "No Subtitles Available"
                    }
                }

                // 4. Audio Tracks Button
                Rectangle {
                    width: 30; height: 28; radius: 6
                    color: audioTrackArea.pressed ? Qt.rgba(255, 255, 255, 0.20) : (audioTrackArea.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08))
                    border.color: audioTrackArea.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: audioCanvas
                        anchors.centerIn: parent
                        width: 13; height: 13
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = audioTrackArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85);
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";
                            // Headband
                            ctx.beginPath();
                            ctx.arc(6.5, 6.0, 4.8, Math.PI, 0, false);
                            ctx.stroke();
                            // Ear cups
                            ctx.fillStyle = audioTrackArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85);
                            ctx.fillRect(1.2, 5.5, 2.0, 5.0);
                            ctx.fillRect(9.8, 5.5, 2.0, 5.0);
                        }
                        Connections {
                            target: audioTrackArea
                            function onContainsMouseChanged() { audioCanvas.requestPaint(); }
                        }
                    }

                    MouseArea {
                        id: audioTrackArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.audioTrackClicked(); root.activityHappened(); }
                    }
                    ModernToolTip {
                        visible: audioTrackArea.containsMouse
                        text: "Audio Tracks"
                    }
                }

                // 5. Equalizer / Settings Button
                Rectangle {
                    width: 30; height: 28; radius: 6
                    color: drawerBtnArea.pressed ? Qt.rgba(255, 255, 255, 0.20) : (drawerBtnArea.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08))
                    border.color: drawerBtnArea.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: eqCanvas
                        anchors.centerIn: parent
                        width: 13; height: 13
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var c = drawerBtnArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85);
                            ctx.strokeStyle = c;
                            ctx.fillStyle = c;
                            ctx.lineWidth = 1.2;
                            ctx.lineCap = "round";

                            // Slider 1
                            ctx.beginPath(); ctx.moveTo(2.5, 1.5); ctx.lineTo(2.5, 11.5); ctx.stroke();
                            ctx.beginPath(); ctx.arc(2.5, 4.0, 1.4, 0, 2 * Math.PI); ctx.fill();

                            // Slider 2
                            ctx.beginPath(); ctx.moveTo(6.5, 1.5); ctx.lineTo(6.5, 11.5); ctx.stroke();
                            ctx.beginPath(); ctx.arc(6.5, 8.8, 1.4, 0, 2 * Math.PI); ctx.fill();

                            // Slider 3
                            ctx.beginPath(); ctx.moveTo(10.5, 1.5); ctx.lineTo(10.5, 11.5); ctx.stroke();
                            ctx.beginPath(); ctx.arc(10.5, 5.5, 1.4, 0, 2 * Math.PI); ctx.fill();
                        }
                        Connections {
                            target: drawerBtnArea
                            function onContainsMouseChanged() { eqCanvas.requestPaint(); }
                        }
                    }

                    MouseArea {
                        id: drawerBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.openDrawerClicked(); root.activityHappened(); }
                    }
                    ModernToolTip {
                        visible: drawerBtnArea.containsMouse
                        text: "Playback Settings & EQ"
                    }
                }

                // 6. Playlist Queue Button
                Rectangle {
                    width: 30; height: 28; radius: 6
                    color: queueBtnArea.pressed ? Qt.rgba(255, 255, 255, 0.20) : (queueBtnArea.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08))
                    border.color: queueBtnArea.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2.0
                        Rectangle { width: 10; height: 1.3; radius: 0.6; color: queueBtnArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85) }
                        Rectangle { width: 10; height: 1.3; radius: 0.6; color: queueBtnArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85) }
                        Rectangle { width: 6.5; height: 1.3; radius: 0.6; color: queueBtnArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85) }
                    }

                    MouseArea {
                        id: queueBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.openPlaylistClicked(); root.activityHappened(); }
                    }
                    ModernToolTip {
                        visible: queueBtnArea.containsMouse
                        text: "Playlist Queue (Ctrl+Q)"
                    }
                }

                // 7. Fullscreen Toggle Button
                Rectangle {
                    width: 30; height: 28; radius: 6
                    color: fsBtnArea.pressed ? Qt.rgba(255, 255, 255, 0.20) : (fsBtnArea.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08))
                    border.color: fsBtnArea.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: fsIconCanvas
                        anchors.centerIn: parent
                        width: 13; height: 13

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = fsBtnArea.containsMouse ? "#ff9500" : Qt.rgba(255, 255, 255, 0.85);
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";

                            if (!root.isFullscreen) {
                                ctx.beginPath(); ctx.moveTo(1.5, 4.0); ctx.lineTo(1.5, 1.5); ctx.lineTo(4.0, 1.5); ctx.stroke();
                                ctx.beginPath(); ctx.moveTo(9.0, 1.5); ctx.lineTo(11.5, 1.5); ctx.lineTo(11.5, 4.0); ctx.stroke();
                                ctx.beginPath(); ctx.moveTo(1.5, 9.0); ctx.lineTo(1.5, 11.5); ctx.lineTo(4.0, 11.5); ctx.stroke();
                                ctx.beginPath(); ctx.moveTo(9.0, 11.5); ctx.lineTo(11.5, 11.5); ctx.lineTo(11.5, 9.0); ctx.stroke();
                            } else {
                                ctx.beginPath(); ctx.moveTo(3.5, 1.5); ctx.lineTo(3.5, 3.5); ctx.lineTo(1.5, 3.5); ctx.stroke();
                                ctx.beginPath(); ctx.moveTo(9.5, 1.5); ctx.lineTo(9.5, 3.5); ctx.lineTo(11.5, 3.5); ctx.stroke();
                                ctx.beginPath(); ctx.moveTo(3.5, 11.5); ctx.lineTo(3.5, 9.5); ctx.lineTo(1.5, 9.5); ctx.stroke();
                                ctx.beginPath(); ctx.moveTo(9.5, 11.5); ctx.lineTo(9.5, 9.5); ctx.lineTo(11.5, 9.5); ctx.stroke();
                            }
                        }

                        Connections {
                            target: root
                            function onIsFullscreenChanged() { fsIconCanvas.requestPaint(); }
                        }
                        Connections {
                            target: fsBtnArea
                            function onContainsMouseChanged() { fsIconCanvas.requestPaint(); }
                        }
                    }

                    MouseArea {
                        id: fsBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.fullscreenToggled(); root.activityHappened(); }
                    }
                    ModernToolTip {
                        visible: fsBtnArea.containsMouse
                        text: root.isFullscreen ? "Exit Fullscreen (F)" : "Fullscreen (F)"
                    }
                }
            }
        }
    }
}
