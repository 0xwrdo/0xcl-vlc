import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import VlcModern 1.0

ApplicationWindow {
    id: window

    visible: true
    width: 1280
    height: 720
    minimumWidth: 260
    minimumHeight: 146
    color: "#000000"

    flags: Qt.Window | Qt.FramelessWindowHint | (isPipMode ? Qt.WindowStaysOnTopHint : Qt.WindowMinMaxButtonsHint)

    property bool isFullscreen: window.visibility === Window.FullScreen
    property bool isPipMode: false
    property real savedWidth: 1280
    property real savedHeight: 720
    property real savedX: 100
    property real savedY: 100
    property int savedVisibility: Window.Windowed

    property bool showControls: true
    property bool showAbRepeat: false
    property bool showStats: false
    property bool showAudioVisualizer: false
    property bool inMediaLibrary: false
    property bool inNetworkDashboard: false

    property bool hasMedia: (videoSurface.hasVideo || (playerController.mediaUrl && playerController.mediaUrl.toString().length > 0))

    Component.onCompleted: {
        if (playerController.mediaUrl.toString().length > 0) {
            videoSurface.openFile(playerController.mediaUrl);
            mediaLibraryModel.setCurrentMedia(playerController.mediaUrl);
        }
    }

    // File Dialog for picking media files
    FileDialog {
        id: fileDialog
        title: "Open Media File"
        nameFilters: ["Media Files (*.mp4 *.mkv *.avi *.mov *.wmv *.webm *.flv *.ts *.m4v *.mp3 *.flac *.wav *.ogg *.aac *.m4a)", "All Files (*)"]
        onAccepted: {
            playerController.openFile(fileDialog.selectedFile);
            videoSurface.openFile(fileDialog.selectedFile);
            mediaLibraryModel.setCurrentMedia(fileDialog.selectedFile);
        }
    }

    // Toggle Picture-in-Picture mode
    function togglePipMode() {
        if (!isPipMode) {
            savedWidth = window.width;
            savedHeight = window.height;
            savedX = window.x;
            savedY = window.y;
            savedVisibility = window.visibility;

            if (window.visibility === Window.FullScreen || window.visibility === Window.Maximized) {
                window.showNormal();
            }

            isPipMode = true;

            // Set compact 16:9 PiP window docked to bottom-right
            var pipW = 440;
            var pipH = 248;
            window.width = pipW;
            window.height = pipH;
            if (Screen.desktopAvailableWidth > pipW && Screen.desktopAvailableHeight > pipH) {
                window.x = Screen.desktopAvailableWidth - pipW - 32;
                window.y = Screen.desktopAvailableHeight - pipH - 48;
            }

            contextDrawer.close();
            playlistDrawer.close();
            commandPalette.close();

            osdToast.showToast("PIP", "Picture-in-Picture", "Floating Mini Player");
        } else {
            isPipMode = false;

            window.width = savedWidth;
            window.height = savedHeight;
            window.x = savedX;
            window.y = savedY;

            if (savedVisibility === Window.FullScreen) {
                window.showFullScreen();
            } else if (savedVisibility === Window.Maximized) {
                window.showMaximized();
            } else {
                window.showNormal();
            }

            osdToast.showToast("WIN", "Picture-in-Picture", "Restored to Window");
        }
    }

    // Idle mouse activity timer (auto-hide controls and cursor after 2.5s ONLY when video is actively playing)
    Timer {
        id: idleTimer
        interval: 2500
        running: true
        repeat: false
        onTriggered: {
            var isPlaying = videoSurface.hasVideo ? videoSurface.isPlaying : playerController.isPlaying;
            if (isPlaying && !controlIsland.containsMouse && !contextMenu.visible && 
                !contextDrawer.opened && !playlistDrawer.opened && !commandPalette.opened) {
                window.showControls = false;
            }
        }
    }

    function resetActivity() {
        window.showControls = true;
        idleTimer.restart();
    }

    // Global Hover Handler for reliable activity tracking across Wayland/X11
    HoverHandler {
        id: globalWindowHover
        onPointChanged: window.resetActivity()
        onHoveredChanged: window.resetActivity()
    }

    // [Change 7] Dynamic Ambient Lighting Backdrop (The "Glow" Effect)
    Rectangle {
        id: ambientGlowBackdrop
        anchors.fill: parent
        z: -1
        visible: !window.isPipMode

        color: ambientSampler.dominantColor
        Behavior on color {
            ColorAnimation { duration: 1400; easing.type: Easing.InOutQuad }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.82) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.95) }
            }
        }
    }

    // Drag-and-Drop Area for Media Files from GNOME Files / Nautilus
    DropArea {
        anchors.fill: parent
        enabled: !window.isPipMode
        onEntered: {
            window.resetActivity();
            osdToast.showToast("FILE", "Drop File", "Release to Play");
        }
        onDropped: {
            if (drop.hasUrls && drop.urls.length > 0) {
                playerController.openFile(drop.urls[0]);
                videoSurface.openFile(drop.urls[0]);
                mediaLibraryModel.setCurrentMedia(drop.urls[0]);
                drop.acceptProposedAction();
            }
        }
    }

    // Root Mouse Tracker for Activity and Gesture Controls (Normal Mode)
    MouseArea {
        id: rootMouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: !window.isPipMode
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: window.showControls ? Qt.ArrowCursor : Qt.BlankCursor

        property real startY: 0
        property bool isLeftHalf: false

        onPositionChanged: window.resetActivity()

        onPressed: function(mouse) {
            startY = mouse.y;
            isLeftHalf = (mouse.x < parent.width / 2);
        }

        // Gesture: Vertical drag for brightness (left) and volume (right)
        onMouseYChanged: {
            if (pressed) {
                var deltaY = startY - mouseY;
                if (Math.abs(deltaY) > 8) {
                    startY = mouseY;
                    if (isLeftHalf) {
                        playerController.brightness = Math.max(0.2, Math.min(2.0, playerController.brightness + (deltaY * 0.005)));
                        osdToast.showToast("BRI", "Brightness", Math.round(playerController.brightness * 100) + "%");
                    } else {
                        playerController.volume = Math.max(0.0, Math.min(1.0, playerController.volume + (deltaY * 0.004)));
                        osdToast.showToast("VOL", "Volume", Math.round(playerController.volume * 100) + "%", playerController.volume);
                    }
                }
            }
        }

        onClicked: function(mouse) {
            window.resetActivity();
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup();
            } else if (mouse.button === Qt.LeftButton) {
                // Click on video toggles play/pause!
                if (videoSurface.hasVideo) {
                    videoSurface.togglePlayPause();
                }
            }
        }

        // Gesture: Double-click left to seek -10s, right to seek +10s, center to fullscreen
        onDoubleClicked: function(mouse) {
            if (mouse.x < parent.width * 0.35) {
                if (videoSurface.hasVideo) videoSurface.skipRelative(-10000);
                else playerController.skipRelative(-10000);
                osdToast.showToast("-10s", "Seek Backward", "-10s");
            } else if (mouse.x > parent.width * 0.65) {
                if (videoSurface.hasVideo) videoSurface.skipRelative(10000);
                else playerController.skipRelative(10000);
                osdToast.showToast("+10s", "Seek Forward", "+10s");
            } else {
                toggleFullscreen();
            }
        }
    }

    // [Change 1] Real Edge-to-Edge Hardware-Accelerated Video Surface
    RealVideoSurface {
        id: videoSurface
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: playlistDrawer.opened ? playlistDrawer.width : 0
        Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        brightness: playerController.brightness

        onDominantColorSampled: function(color) {
            ambientSampler.setDominantColor(color);
        }

        Connections {
            target: playerController
            function onMediaOpened(title) {
                videoSurface.openFile(playerController.mediaUrl);
            }
            function onMediaUrlChanged() {
                if (playerController.mediaUrl.toString().length > 0) {
                    videoSurface.openFile(playerController.mediaUrl);
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 16
            visible: !hasMedia && !window.inMediaLibrary && !window.inNetworkDashboard && !window.showAudioVisualizer && !window.isPipMode

            // VLC Custom Dhaka Topi 3D Hero Cone Logo
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 140
                height: 140
                source: "qrc:/qml/vlc_cone_modern.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "VLC media player"
                font.pixelSize: 22
                font.weight: Font.DemiBold
                color: "#ffffff"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Drop any video/audio file here or open from disk"
                font.pixelSize: 14
                font.weight: Font.Normal
                color: Qt.rgba(255, 255, 255, 0.70)
            }

            Item { width: 1; height: 6 }

            // Refined Modern 'Open File...' Action Container (Matches Sleek Sidebar Aesthetics)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 148
                height: 38
                radius: 8
                gradient: Gradient {
                    GradientStop { 
                        position: 0.0 
                        color: openFileArea.pressed ? "#d96500" : (openFileArea.containsMouse ? "#ffa726" : "#ff9500") 
                    }
                    GradientStop { 
                        position: 1.0 
                        color: openFileArea.pressed ? "#bf5200" : (openFileArea.containsMouse ? "#f57c00" : "#e67300") 
                    }
                }
                border.color: openFileArea.containsMouse ? Qt.rgba(255, 255, 255, 0.35) : Qt.rgba(255, 255, 255, 0.18)
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    // Folder Vector Icon
                    Canvas {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 14
                        Layout.alignment: Qt.AlignVCenter
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "#111111";
                            ctx.strokeStyle = "#111111";
                            ctx.lineWidth = 1.0;
                            // Folder tab & body
                            ctx.beginPath();
                            ctx.moveTo(1.0, 3.0);
                            ctx.lineTo(5.5, 3.0);
                            ctx.lineTo(7.5, 5.0);
                            ctx.lineTo(15.0, 5.0);
                            ctx.lineTo(15.0, 13.0);
                            ctx.lineTo(1.0, 13.0);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }

                    Text {
                        text: "Open File..."
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#111111"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: openFileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fileDialog.open()
                }
            }
        }

        // [Change 14] Real-time Audio Spectrum Visualizer
        AudioSpectrumVisualizer {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 110
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 120, 520)
            height: 72
            visible: window.showAudioVisualizer && !window.isPipMode
        }
    }

    // ========================================================
    // Picture-in-Picture (PiP) Floating Controls Overlay
    // ========================================================
    Item {
        id: pipOverlay
        anchors.fill: parent
        visible: window.isPipMode

        HoverHandler {
            id: pipHoverHandler
        }

        // Background area for window dragging, play/pause click, double-click restore, right-click context menu
        MouseArea {
            id: pipDragArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            property int pressX: 0
            property int pressY: 0
            property bool isDragging: false

            onPressed: function(mouse) {
                pressX = mouse.x;
                pressY = mouse.y;
                isDragging = false;
            }

            onPositionChanged: function(mouse) {
                if (pressed && (mouse.buttons & Qt.LeftButton)) {
                    var dx = mouse.x - pressX;
                    var dy = mouse.y - pressY;
                    if (!isDragging && (dx * dx + dy * dy > 16)) {
                        isDragging = true;
                        window.startSystemMove();
                    }
                }
            }

            onDoubleClicked: window.togglePipMode()

            onClicked: function(mouse) {
                if (isDragging) return;
                if (mouse.button === Qt.RightButton) {
                    contextMenu.popup();
                } else if (mouse.button === Qt.LeftButton) {
                    if (videoSurface.hasVideo) videoSurface.togglePlayPause();
                    else playerController.togglePlayPause();
                }
            }
        }

        // Overlay controls layer - solid visibility on hover or when video is paused
        Rectangle {
            id: pipControlsLayer
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: (pipHoverHandler.hovered || !(videoSurface.hasVideo ? videoSurface.isPlaying : playerController.isPlaying)) ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 160 } }

            // Top action bar in PiP
            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 8

                Canvas {
                    Layout.preferredWidth: 14; Layout.preferredHeight: 14
                    Layout.alignment: Qt.AlignVCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = "#ff8800";
                        ctx.beginPath();
                        ctx.moveTo(1, 13); ctx.lineTo(13, 13); ctx.lineTo(13, 14); ctx.lineTo(1, 14); ctx.fill();
                        ctx.beginPath();
                        ctx.moveTo(3, 13); ctx.lineTo(6, 1); ctx.lineTo(8, 1); ctx.lineTo(11, 13); ctx.fill();
                        ctx.fillStyle = "white";
                        ctx.fillRect(4.5, 7.5, 5, 2);
                    }
                }

                Text {
                    text: "VLC PiP"
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.pixelSize: 11
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Expand / Restore Button
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: restoreMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.4)
                    Behavior on color { ColorAnimation { duration: 120 } }

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
                            ctx.moveTo(1, 4); ctx.lineTo(1, 1); ctx.lineTo(4, 1);
                            ctx.moveTo(7, 1); ctx.lineTo(10, 1); ctx.lineTo(10, 4);
                            ctx.moveTo(1, 7); ctx.lineTo(1, 10); ctx.lineTo(4, 10);
                            ctx.moveTo(7, 10); ctx.lineTo(10, 10); ctx.lineTo(10, 7);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        id: restoreMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.togglePipMode()
                    }
                    ModernToolTip { visible: restoreMouse.containsMouse; text: "Restore Full Window (P)" }
                }

                // Close Button
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: pipCloseMouse.containsMouse ? "#e81123" : Qt.rgba(0, 0, 0, 0.4)
                    Behavior on color { ColorAnimation { duration: 120 } }

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
                        id: pipCloseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.close()
                    }
                }
            }

            // Center Play/Pause button
            Rectangle {
                anchors.centerIn: parent
                width: 44; height: 44; radius: 22
                color: pipPlayMouse.containsMouse ? "#ffa622" : "#ff9500"
                Behavior on color { ColorAnimation { duration: 120 } }

                // Pause Bars
                Row {
                    anchors.centerIn: parent
                    spacing: 3.5
                    visible: videoSurface.hasVideo ? videoSurface.isPlaying : playerController.isPlaying
                    Rectangle { width: 3.5; height: 14; radius: 1.2; color: "#111111" }
                    Rectangle { width: 3.5; height: 14; radius: 1.2; color: "#111111" }
                }

                // Play Triangle
                Canvas {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1.5
                    width: 14; height: 16
                    visible: !(videoSurface.hasVideo ? videoSurface.isPlaying : playerController.isPlaying)
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = "#111111";
                        ctx.beginPath();
                        ctx.moveTo(1.5, 1);
                        ctx.lineTo(13.0, 8.0);
                        ctx.lineTo(1.5, 15);
                        ctx.closePath();
                        ctx.fill();
                    }
                }

                MouseArea {
                    id: pipPlayMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (videoSurface.hasVideo) videoSurface.togglePlayPause();
                        else playerController.togglePlayPause();
                    }
                }
            }

            // Bottom Seek Slider and Time
            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: {
                            var ms = videoSurface.hasVideo ? videoSurface.currentTimeMs : playerController.currentTimeMs;
                            var s = Math.floor(ms / 1000);
                            var m = Math.floor(s / 60);
                            var sec = s % 60;
                            return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
                        }
                        color: "white"
                        font.pixelSize: 10
                        font.family: "Monospace"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: {
                            var total = videoSurface.hasVideo ? videoSurface.durationMs : playerController.durationMs;
                            var cur = videoSurface.hasVideo ? videoSurface.currentTimeMs : playerController.currentTimeMs;
                            var rem = Math.max(0, total - cur);
                            var s = Math.floor(rem / 1000);
                            var m = Math.floor(s / 60);
                            var sec = s % 60;
                            return "-" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
                        }
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 10
                        font.family: "Monospace"
                    }
                }

                Slider {
                    id: pipSeekSlider
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    value: videoSurface.hasVideo ? videoSurface.position : playerController.position

                    background: Rectangle {
                        x: pipSeekSlider.leftPadding
                        y: pipSeekSlider.topPadding + pipSeekSlider.availableHeight / 2 - height / 2
                        width: pipSeekSlider.availableWidth
                        height: 3
                        radius: 1.5
                        color: Qt.rgba(1, 1, 1, 0.25)

                        Rectangle {
                            width: pipSeekSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#ff9500"
                            radius: 1.5
                        }
                    }

                    handle: Rectangle {
                        x: pipSeekSlider.leftPadding + pipSeekSlider.visualPosition * (pipSeekSlider.availableWidth - width)
                        y: pipSeekSlider.topPadding + pipSeekSlider.availableHeight / 2 - height / 2
                        width: 8; height: 8; radius: 4
                        color: "#ff9500"
                        border.color: "white"
                        border.width: 1.5
                    }

                    onMoved: {
                        if (videoSurface.hasVideo) videoSurface.seek(pipSeekSlider.value);
                        else playerController.position = pipSeekSlider.value;
                    }
                }
            }
        }
    }

    // Smooth Dark Top Gradient Scrim Mask (Ensures 100% visibility over bright sky, snow, or white video)
    Rectangle {
        id: topGradientScrim
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 110
        z: 14
        opacity: (window.showControls && !window.isPipMode) ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.94) }
            GradientStop { position: 0.40; color: Qt.rgba(0, 0, 0, 0.65) }
            GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.25) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // [Change 1] Floating Window Header & Overlay Controls with High Legibility
    Item {
        id: topWindowBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44
        z: 15
        opacity: (window.showControls && !window.isPipMode) ? 1.0 : 0.0
        visible: opacity > 0.0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Window Dragging Area (covers entire top area except the window caption buttons)
        MouseArea {
            id: titleDragArea
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: winCaptionCapsule.left
            anchors.rightMargin: 8
            acceptedButtons: Qt.LeftButton

            onPressed: function(mouse) {
                window.startSystemMove();
            }

            onDoubleClicked: function(mouse) {
                if (window.visibility === Window.Maximized || window.visibility === Window.FullScreen) {
                    window.showNormal();
                } else {
                    window.showMaximized();
                }
            }
        }

        // Left Floating Branding & Media Title (Directly Overlaid on Video with high-contrast shadow)
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: playlistDrawer.opened ? (playlistDrawer.width + 16) : 16
            Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: winCaptionCapsule.left
            anchors.rightMargin: 16
            spacing: 10

            // VLC Custom Dhaka Topi Cone Logo (Top-Left Branded Icon)
            Image {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                source: "qrc:/qml/vlc_cone_modern_transparent.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Item {
                Layout.preferredWidth: vlcTitleText.implicitWidth
                Layout.preferredHeight: vlcTitleText.implicitHeight
                Layout.alignment: Qt.AlignVCenter

                Text {
                    x: 1; y: 1
                    text: vlcTitleText.text
                    font: vlcTitleText.font
                    color: Qt.rgba(0, 0, 0, 0.95)
                }
                Text {
                    id: vlcTitleText
                    text: "VLC"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                }
            }

            // High-precision geometric divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 12
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                color: Qt.rgba(255, 255, 255, 0.45)
                visible: titleTextActual.text.length > 0
            }

            // High-contrast media filename text with drop shadow for 100% legibility over any video
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titleTextActual.implicitHeight
                Layout.alignment: Qt.AlignVCenter
                visible: titleTextActual.text.length > 0

                Text {
                    x: 1; y: 1
                    width: parent.width
                    text: titleTextActual.text
                    font: titleTextActual.font
                    color: Qt.rgba(0, 0, 0, 0.95)
                    elide: Text.ElideRight
                }
                Text {
                    id: titleTextActual
                    width: parent.width
                    text: {
                        var title = videoSurface.hasVideo ? videoSurface.mediaTitle : playerController.mediaTitle;
                        return (title && title.length > 0) ? title : "";
                    }
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    elide: Text.ElideRight
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // Minimalist Window Caption Controls (Sleek dark acrylic capsule, zero 1px debug border)
        Rectangle {
            id: winCaptionCapsule
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 30
            width: 116
            radius: 7
            color: Qt.rgba(0, 0, 0, 0.50)
            clip: true
            z: 15

            Row {
                id: winCaptionRow
                anchors.fill: parent
                spacing: 0

                // Minimize Button
                Rectangle {
                    width: 38
                    height: 30
                    color: minMouse.pressed ? Qt.rgba(255, 255, 255, 0.25) : (minMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 11
                        height: 1.5
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: minMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: window.showMinimized()
                    }
                    ModernToolTip { visible: minMouse.containsMouse; text: "Minimize" }
                }

                // Maximize / Restore Button
                Rectangle {
                    width: 38
                    height: 30
                    color: maxMouse.pressed ? Qt.rgba(255, 255, 255, 0.25) : (maxMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: maxCanvas
                        anchors.centerIn: parent
                        width: 12
                        height: 12

                        property bool isMax: (window.visibility === Window.Maximized || window.visibility === Window.FullScreen)

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.2;

                            if (!isMax) {
                                ctx.strokeRect(1, 1, 10, 10);
                            } else {
                                ctx.beginPath();
                                ctx.moveTo(3.5, 1.5);
                                ctx.lineTo(10.5, 1.5);
                                ctx.lineTo(10.5, 8.5);
                                ctx.stroke();
                                ctx.strokeRect(1.5, 3.5, 7.0, 7.0);
                            }
                        }

                        Connections {
                            target: window
                            function onVisibilityChanged() { maxCanvas.requestPaint(); }
                        }
                    }

                    MouseArea {
                        id: maxMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: {
                            if (window.visibility === Window.Maximized || window.visibility === Window.FullScreen) {
                                window.showNormal();
                            } else {
                                window.showMaximized();
                            }
                        }
                    }
                    ModernToolTip { visible: maxMouse.containsMouse; text: (window.visibility === Window.Maximized || window.visibility === Window.FullScreen) ? "Restore Down" : "Maximize" }
                }

                // Close Button
                Rectangle {
                    width: 40
                    height: 30
                    color: closeMouse.pressed ? "#bf0f1d" : (closeMouse.containsMouse ? "#e81123" : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Canvas {
                        id: closeCanvas
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(0.5, 0.5); ctx.lineTo(9.5, 9.5);
                            ctx.moveTo(9.5, 0.5); ctx.lineTo(0.5, 9.5);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: window.close()
                    }
                    ModernToolTip { visible: closeMouse.containsMouse; text: "Close (Alt+F4)" }
                }
            }
        }
    }

    // [Change 4] Grid-Based Media Library Overlay
    MediaLibraryGrid {
        anchors.fill: parent
        visible: window.inMediaLibrary && !window.isPipMode
        onCloseLibrary: window.inMediaLibrary = false
        onMediaSelected: {
            window.inMediaLibrary = false;
            playerController.openFile(fileUrl);
            videoSurface.openFile(fileUrl);
        }
    }

    // [Change 9] Network Stream Dashboard Overlay
    NetworkDashboard {
        anchors.fill: parent
        visible: window.inNetworkDashboard && !window.isPipMode
        onCloseDashboard: window.inNetworkDashboard = false
        onServerSelected: {
            window.inNetworkDashboard = false;
            playerController.openFile(url);
            osdToast.showToast("NET", "Connected to", name);
        }
    }

    // [Change 17] A/B Repeat Loop Bar
    AbRepeatBar {
        anchors.bottom: controlIsland.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 96, 680)
        visible: window.showAbRepeat && window.showControls && !window.inMediaLibrary && !window.inNetworkDashboard && !window.isPipMode
        onLoopRangeChanged: {
            osdToast.showToast("LOOP", "A-B Loop Range", Math.round(a*100) + "% - " + Math.round(b*100) + "%");
        }
    }

    // Bottom Gradient Scrim Mask (Smoothly blends video into the docked control bar)
    Rectangle {
        id: bottomGradientScrim
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: playlistDrawer.opened ? playlistDrawer.width : 0
        Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        anchors.right: parent.right
        height: 120
        z: 74
        opacity: (window.hasMedia && window.showControls && !window.isPipMode && !window.inMediaLibrary && !window.inNetworkDashboard) ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.40) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.80) }
        }
    }

    // [Change 2] Docked Screen-Wide Control Bar with Full-Width Scrubber (Zero Dead Space Underneath)
    FloatingControlIsland {
        id: controlIsland
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (window.hasMedia && window.showControls) ? 0 : -implicitHeight
        anchors.left: parent.left
        anchors.leftMargin: playlistDrawer.opened ? playlistDrawer.width : 0
        Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        anchors.right: parent.right
        anchors.rightMargin: 0
        z: 75
        visible: window.hasMedia && !window.isPipMode && !window.inMediaLibrary && !window.inNetworkDashboard

        isPlaying: videoSurface.hasVideo ? videoSurface.isPlaying : playerController.isPlaying
        progress: videoSurface.hasVideo ? videoSurface.position : (playerController.durationMs > 0 ? playerController.position : 0.0)
        volumeLevel: videoSurface.hasVideo ? videoSurface.volume : playerController.volume
        isMuted: videoSurface.hasVideo ? videoSurface.isMuted : playerController.isMuted
        totalDurationMs: videoSurface.hasVideo ? videoSurface.durationMs : playerController.durationMs
        isFullscreen: window.isFullscreen
        playbackRate: videoSurface.hasVideo ? videoSurface.playbackRate : playerController.playbackRate
        fillMode: videoSurface.fillMode
        hasSubtitles: videoSurface.hasVideo && videoSurface.subtitleTracks && videoSurface.subtitleTracks.length > 0
        areSubtitlesEnabled: videoSurface.hasVideo && videoSurface.currentSubtitleTrack !== -1
        currentDeviceType: videoSurface.hasVideo ? videoSurface.currentDeviceType : playerController.currentDeviceType
        currentDeviceName: videoSurface.hasVideo ? videoSurface.currentDeviceName : playerController.currentDeviceName
        isAudioOutputMenuOpen: audioOutputMenu.opened

        currentTime: {
            var ms = videoSurface.hasVideo ? videoSurface.currentTimeMs : playerController.currentTimeMs;
            if (ms <= 0) return "00:00";
            var s = Math.floor(ms / 1000);
            var h = Math.floor(s / 3600);
            var m = Math.floor((s % 3600) / 60);
            var sec = s % 60;
            if (h > 0)
                return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
            else
                return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
        }

        remainingTime: {
            var total = videoSurface.hasVideo ? videoSurface.durationMs : playerController.durationMs;
            var cur = videoSurface.hasVideo ? videoSurface.currentTimeMs : playerController.currentTimeMs;
            if (total <= 0) return "-00:00";
            var rem = Math.max(0, total - cur);
            var s = Math.floor(rem / 1000);
            var h = Math.floor(s / 3600);
            var m = Math.floor((s % 3600) / 60);
            var sec = s % 60;
            if (h > 0)
                return "-" + (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
            else
                return "-" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
        }

        totalDurationStr: {
            var total = videoSurface.hasVideo ? videoSurface.durationMs : playerController.durationMs;
            if (total <= 0) return "00:00";
            var s = Math.floor(total / 1000);
            var h = Math.floor(s / 3600);
            var m = Math.floor((s % 3600) / 60);
            var sec = s % 60;
            if (h > 0)
                return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
            else
                return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec;
        }

        opacity: window.showControls ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        onActivityHappened: window.resetActivity()

        onPlayPauseClicked: {
            if (videoSurface.hasVideo) {
                videoSurface.togglePlayPause();
            } else {
                playerController.togglePlayPause();
            }
        }
        onPreviousClicked: {
            var prevUrl = mediaLibraryModel.getPreviousUrl();
            if (prevUrl.toString().length > 0) {
                playerController.openFile(prevUrl);
                videoSurface.openFile(prevUrl);
                osdToast.showToast("PREV", "Previous Media", videoSurface.mediaTitle);
            }
        }
        onNextClicked: {
            var nextUrl = mediaLibraryModel.getNextUrl();
            if (nextUrl.toString().length > 0) {
                playerController.openFile(nextUrl);
                videoSurface.openFile(nextUrl);
                osdToast.showToast("NEXT", "Next Media", videoSurface.mediaTitle);
            }
        }
        onSkipBackwardClicked: {
            if (videoSurface.hasVideo) videoSurface.skipRelative(-10000);
            else playerController.skipRelative(-10000);
            osdToast.showToast("-10s", "Seek Backward", "-10s");
        }
        onSkipForwardClicked: {
            if (videoSurface.hasVideo) videoSurface.skipRelative(10000);
            else playerController.skipRelative(10000);
            osdToast.showToast("+10s", "Seek Forward", "+10s");
        }
        onSpeedClicked: {
            var speeds = [1.0, 1.25, 1.5, 2.0, 0.5, 0.75];
            var cur = videoSurface.hasVideo ? videoSurface.playbackRate : playerController.playbackRate;
            var nextSpeed = 1.0;
            for (var i = 0; i < speeds.length; i++) {
                if (Math.abs(cur - speeds[i]) < 0.05) {
                    nextSpeed = speeds[(i + 1) % speeds.length];
                    break;
                }
            }
            if (videoSurface.hasVideo) videoSurface.setPlaybackRate(nextSpeed);
            playerController.playbackRate = nextSpeed;
            osdToast.showToast("SPD", "Playback Speed", nextSpeed.toFixed(2) + "x");
        }
        onAspectRatioClicked: {
            var nextMode = (videoSurface.fillMode + 1) % 3;
            videoSurface.setFillMode(nextMode);
            var names = ["Fit (Original)", "Fill (Crop)", "Stretch"];
            osdToast.showToast("ASPECT", "Aspect Ratio", names[nextMode]);
        }
        onAudioTrackClicked: {
            if (contextDrawer.opened && contextDrawer.activeTab === 0) {
                contextDrawer.close();
            } else {
                playlistDrawer.close();
                contextDrawer.open();
                contextDrawer.activeTab = 0;
            }
        }
        onSeekRequested: function(pos) {
            if (videoSurface.hasVideo)
                videoSurface.seek(pos);
            else
                playerController.position = pos;
        }
        onVolumeChanged: function(vol) {
            if (videoSurface.hasVideo)
                videoSurface.setVolume(vol);
            playerController.volume = vol;
            var pct = Math.round(vol * 100);
            if (pct > 100) {
                osdToast.showToast("BOOST", "Volume Overdrive", pct + "%", vol);
            } else {
                osdToast.showToast("VOL", "Volume", pct + "%", vol);
            }
        }
        onMuteToggled: {
            if (videoSurface.hasVideo) {
                videoSurface.toggleMute();
                playerController.isMuted = videoSurface.isMuted;
                if (videoSurface.isMuted) {
                    osdToast.showToast("MUTE", "Volume", "Muted");
                } else {
                    var pct = Math.round(videoSurface.volume * 100);
                    osdToast.showToast("VOL", "Volume", pct + "%", videoSurface.volume);
                }
            } else {
                playerController.isMuted = !playerController.isMuted;
                osdToast.showToast("MUTE", "Volume", playerController.isMuted ? "Muted" : "Unmuted");
            }
        }
        onFullscreenToggled: {
            toggleFullscreen();
        }
        onPipToggled: {
            togglePipMode();
        }
        onOpenDrawerClicked: {
            if (contextDrawer.opened) {
                contextDrawer.close();
            } else {
                playlistDrawer.close();
                contextDrawer.open();
            }
        }
        onCcClicked: {
            if (!controlIsland.hasSubtitles) {
                osdToast.showToast("CC", "Subtitles", "No Subtitles Available");
                return;
            }
            if (videoSurface.currentSubtitleTrack !== -1) {
                videoSurface.setSubtitleTrack(-1);
                osdToast.showToast("CC", "Subtitles", "Subtitles Disabled");
            } else {
                videoSurface.setSubtitleTrack(0);
                var trackName = (videoSurface.subtitleTracks && videoSurface.subtitleTracks.length > 0)
                                ? videoSurface.subtitleTracks[0] : "Track 1";
                osdToast.showToast("CC", "Subtitles Enabled", trackName);
            }
        }
        onOpenPlaylistClicked: {
            if (playlistDrawer.opened) {
                playlistDrawer.close();
            } else {
                contextDrawer.close();
                audioOutputMenu.close();
                playlistDrawer.open();
            }
        }
        onOpenAudioOutputClicked: {
            if (audioOutputMenu.opened) {
                audioOutputMenu.close();
            } else {
                contextDrawer.close();
                playlistDrawer.close();
                audioOutputMenu.open();
            }
        }
    }

    // [Change 18] Stats for Nerds Telemetry Overlay
    StatsForNerds {
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.left: parent.left
        anchors.leftMargin: 20
        visible: window.showStats && !window.isPipMode
        onCloseRequested: window.showStats = false
    }

    // [Change 10] Modern OSD Toast Notification
    ModernOsdToast {
        id: osdToast
        anchors.top: parent.top
        anchors.topMargin: window.isPipMode ? 16 : 64
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Dismiss backdrop when Play Queue is open (covers canvas area outside the drawer)
    MouseArea {
        anchors.top: parent.top
        anchors.bottom: controlIsland.top
        anchors.left: parent.left
        anchors.leftMargin: playlistDrawer.opened ? playlistDrawer.width : 0
        anchors.right: parent.right
        enabled: playlistDrawer.opened
        visible: playlistDrawer.opened
        z: 95
        onClicked: playlistDrawer.close()
    }

    // Play Queue Sidebar (Full-height sleek left drawer at z: 100)
    PlaylistDrawer {
        id: playlistDrawer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 100
    }

    // Dismiss backdrop when Settings Panel is open (never overlaps control island)
    MouseArea {
        anchors.top: parent.top
        anchors.bottom: controlIsland.top
        anchors.left: parent.left
        anchors.right: parent.right
        enabled: contextDrawer.opened
        visible: contextDrawer.opened
        z: 48
        onClicked: contextDrawer.close()
    }

    // [Change 3] Floating Playback Settings Panel (Overlay, Never Shoves Video, Safely Above Bottom Controls)
    ContextDrawer {
        id: contextDrawer
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.bottom: controlIsland.top
        anchors.bottomMargin: 10
        videoSurface: videoSurface
        z: 50
    }

    // Dismiss backdrop when Audio Output Menu is open (never overlaps control island)
    MouseArea {
        anchors.top: parent.top
        anchors.bottom: controlIsland.top
        anchors.left: parent.left
        anchors.right: parent.right
        enabled: audioOutputMenu.opened
        visible: audioOutputMenu.opened
        z: 68
        onClicked: audioOutputMenu.close()
    }

    // Floating Audio Output Selector Menu (Overlay directly above volume area, highest z-index)
    AudioOutputMenu {
        id: audioOutputMenu
        anchors.right: parent.right
        anchors.rightMargin: 120
        anchors.bottom: controlIsland.top
        anchors.bottomMargin: 10
        videoSurface: videoSurface
        playerController: playerController
        z: 70
        onDeviceSelected: function(name) {
            osdToast.showToast("AUDIO", "Audio Output", name);
        }
    }

    // [Change 16] Command Palette Popup
    CommandPalette {
        id: commandPalette
        onActionTriggered: {
            if (commandId === "play_pause") {
                if (videoSurface.hasVideo) videoSurface.togglePlayPause();
                else playerController.togglePlayPause();
            } else if (commandId === "fullscreen") {
                toggleFullscreen();
            } else if (commandId === "pip") {
                togglePipMode();
            } else if (commandId === "stats") {
                window.showStats = !window.showStats;
            } else if (commandId === "sub_sync") {
                contextDrawer.open();
                contextDrawer.activeTab = 1;
            } else if (commandId === "eq") {
                contextDrawer.open();
            } else if (commandId === "medialib") {
                window.inMediaLibrary = true;
            } else if (commandId === "network") {
                window.inNetworkDashboard = true;
            } else if (commandId === "faster") {
                playerController.playbackRate = Math.min(3.0, playerController.playbackRate + 0.1);
                osdToast.showToast("SPD", "Playback Speed", playerController.playbackRate.toFixed(2) + "x");
            } else if (commandId === "slower") {
                playerController.playbackRate = Math.max(0.2, playerController.playbackRate - 0.1);
                osdToast.showToast("SPD", "Playback Speed", playerController.playbackRate.toFixed(2) + "x");
            } else if (commandId === "normalspeed") {
                playerController.playbackRate = 1.0;
                osdToast.showToast("SPD", "Playback Speed", "1.00x (Normal)");
            } else if (commandId === "mute") {
                controlIsland.muteToggled();
            }
        }
    }

    // [Change 6] Consolidated Right-Click Menu
    PlayerContextMenu {
        id: contextMenu
        isPlaying: videoSurface.hasVideo ? videoSurface.isPlaying : playerController.isPlaying
        isFullscreen: window.isFullscreen
        isPip: window.isPipMode
        audioTracks: videoSurface.audioTracks
        subtitleTracks: videoSurface.subtitleTracks
        currentAudioTrack: videoSurface.currentAudioTrack
        currentSubtitleTrack: videoSurface.currentSubtitleTrack

        onPlayPauseTriggered: {
            if (videoSurface.hasVideo) videoSurface.togglePlayPause();
            else playerController.togglePlayPause();
        }
        onFullscreenTriggered: {
            toggleFullscreen();
        }
        onPipTriggered: {
            togglePipMode();
        }
        onSpeedSelected: {
            videoSurface.setPlaybackRate(speed);
            playerController.playbackRate = speed;
            osdToast.showToast("SPD", "Playback Speed", speed.toFixed(2) + "x");
        }
        onAudioTrackSelected: function(index) {
            videoSurface.setAudioTrack(index);
        }
        onSubtitleTrackSelected: function(index) {
            videoSurface.setSubtitleTrack(index);
        }
        onOpenDrawerTriggered: {
            contextDrawer.open();
        }
    }

    function toggleFullscreen() {
        if (window.isPipMode) {
            togglePipMode();
            return;
        }
        if (window.visibility === Window.FullScreen) {
            window.showNormal();
            osdToast.showToast("WIN", "Window Mode", "Windowed");
        } else {
            window.showFullScreen();
            osdToast.showToast("FULL", "Fullscreen", "Full Screen Mode");
        }
    }

    // Global Key Shortcuts
    Shortcut { sequence: "Ctrl+K"; onActivated: commandPalette.open() }
    Shortcut { sequence: "Ctrl+I"; onActivated: window.showStats = !window.showStats }
    Shortcut { sequence: "Ctrl+L"; onActivated: window.inMediaLibrary = !window.inMediaLibrary }
    Shortcut { sequence: "Ctrl+N"; onActivated: window.inNetworkDashboard = !window.inNetworkDashboard }
    Shortcut { sequence: "Ctrl+B"; onActivated: window.showAbRepeat = !window.showAbRepeat }
    Shortcut { sequence: "Ctrl+M"; onActivated: window.showAudioVisualizer = !window.showAudioVisualizer }
    Shortcut { sequence: "Ctrl+Q"; onActivated: playlistDrawer.open() }
    Shortcut {
        sequence: "Space"
        onActivated: {
            if (videoSurface.hasVideo) videoSurface.togglePlayPause();
            else playerController.togglePlayPause();
        }
    }
    Shortcut { sequence: "F"; onActivated: toggleFullscreen() }
    Shortcut { sequence: "P"; onActivated: togglePipMode() }
    Shortcut { sequence: "V"; onActivated: controlIsland.ccClicked() }
    Shortcut { sequence: "M"; onActivated: controlIsland.muteToggled() }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (window.isPipMode) togglePipMode();
            else if (window.isFullscreen) toggleFullscreen();
        }
    }
    Shortcut { sequence: "Right"; onActivated: { if (videoSurface.hasVideo) videoSurface.skipRelative(5000); else playerController.skipRelative(5000); osdToast.showToast("+5s", "Seek Forward", "+5s"); } }
    Shortcut { sequence: "Left"; onActivated: { if (videoSurface.hasVideo) videoSurface.skipRelative(-5000); else playerController.skipRelative(-5000); osdToast.showToast("-5s", "Seek Backward", "-5s"); } }
    Shortcut { sequence: "Up"; onActivated: { var v = Math.min(1.0, (videoSurface.hasVideo ? videoSurface.volume : playerController.volume) + 0.05); if (videoSurface.hasVideo) videoSurface.setVolume(v); playerController.volume = v; osdToast.showToast("VOL", "Volume", Math.round(v*100) + "%", v); } }
    Shortcut { sequence: "Down"; onActivated: { var v = Math.max(0.0, (videoSurface.hasVideo ? videoSurface.volume : playerController.volume) - 0.05); if (videoSurface.hasVideo) videoSurface.setVolume(v); playerController.volume = v; osdToast.showToast("VOL", "Volume", Math.round(v*100) + "%", v); } }
}
