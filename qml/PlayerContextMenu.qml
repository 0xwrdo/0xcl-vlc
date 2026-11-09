import QtQuick 2.15
import QtQuick.Controls 2.15

Menu {
    id: root

    property bool isPlaying: false
    property bool isFullscreen: false
    property bool isPip: false
    property var audioTracks: []
    property var subtitleTracks: []
    property int currentAudioTrack: 0
    property int currentSubtitleTrack: 0

    signal playPauseTriggered()
    signal fullscreenTriggered()
    signal pipTriggered()
    signal openDrawerTriggered()
    signal audioTrackSelected(int index)
    signal subtitleTrackSelected(int index)
    signal speedSelected(real speed)

    // Dark acrylic glass styling
    background: Rectangle {
        implicitWidth: 240
        radius: 12
        color: Qt.rgba(0.10, 0.11, 0.15, 0.95)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
    }

    delegate: MenuItem {
        id: menuItem
        implicitHeight: 36
        
        contentItem: Row {
            spacing: 12
            leftPadding: 16
            rightPadding: 16

            Text {
                text: menuItem.text
                font.pixelSize: 13
                color: menuItem.highlighted ? "#ff9500" : "white"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        background: Rectangle {
            color: menuItem.highlighted ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            radius: 6
            anchors.fill: parent
            anchors.margins: 2
        }
    }

    // 1. Play / Pause
    Action {
        text: root.isPlaying ? "Pause                  Space" : "Play                   Space"
        onTriggered: root.playPauseTriggered()
    }

    // 2. Fullscreen Toggle
    Action {
        text: root.isFullscreen ? "Exit Fullscreen            F" : "Enter Fullscreen           F"
        onTriggered: root.fullscreenTriggered()
    }

    // 3. Picture in Picture Toggle
    Action {
        text: root.isPip ? "Exit Picture-in-Picture        P" : "Picture-in-Picture               P"
        onTriggered: root.pipTriggered()
    }

    MenuSeparator {
        contentItem: Rectangle {
            implicitHeight: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }
    }

    // 3. Audio Tracks Cascaded Menu
    Menu {
        id: audioMenu
        title: "Audio Tracks"

        background: Rectangle {
            implicitWidth: 260
            radius: 10
            color: Qt.rgba(0.10, 0.11, 0.15, 0.95)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
        }

        Instantiator {
            model: root.audioTracks && root.audioTracks.length > 0 ? root.audioTracks : ["Track 1: Stereo [Default]"]
            onObjectAdded: function(index, object) { audioMenu.addAction(object) }
            onObjectRemoved: function(index, object) { audioMenu.removeAction(object) }
            delegate: Action {
                text: modelData
                checkable: true
                checked: index === root.currentAudioTrack
                onTriggered: root.audioTrackSelected(index)
            }
        }
    }

    // 4. Subtitle Tracks Cascaded Menu
    Menu {
        id: subMenu
        title: "Subtitle Tracks"

        background: Rectangle {
            implicitWidth: 260
            radius: 10
            color: Qt.rgba(0.10, 0.11, 0.15, 0.95)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
        }

        Action {
            text: "Disable Subtitles"
            checkable: true
            checked: root.currentSubtitleTrack === -1
            onTriggered: root.subtitleTrackSelected(-1)
        }

        Instantiator {
            model: root.subtitleTracks
            onObjectAdded: function(index, object) { subMenu.addAction(object) }
            onObjectRemoved: function(index, object) { subMenu.removeAction(object) }
            delegate: Action {
                text: modelData
                checkable: true
                checked: index === root.currentSubtitleTrack
                onTriggered: root.subtitleTrackSelected(index)
            }
        }
    }

    // 5. Playback Speed
    Menu {
        title: "Playback Speed"

        background: Rectangle {
            implicitWidth: 160
            radius: 10
            color: Qt.rgba(0.10, 0.11, 0.15, 0.95)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
        }

        Action { text: "0.50x"; onTriggered: root.speedSelected(0.5) }
        Action { text: "0.75x"; onTriggered: root.speedSelected(0.75) }
        Action { text: "1.00x (Normal)"; checkable: true; checked: true; onTriggered: root.speedSelected(1.0) }
        Action { text: "1.25x"; onTriggered: root.speedSelected(1.25) }
        Action { text: "1.50x"; onTriggered: root.speedSelected(1.5) }
        Action { text: "2.00x"; onTriggered: root.speedSelected(2.0) }
    }

    MenuSeparator {
        contentItem: Rectangle {
            implicitHeight: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }
    }

    // 6. Settings Drawer Bridge
    Action {
        text: "Playback Settings & Equalizer..."
        onTriggered: root.openDrawerTriggered()
    }
}
