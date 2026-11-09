import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    implicitWidth: 420
    implicitHeight: 330
    radius: 12

    // Zero-overhead GPU rendering
    layer.enabled: true
    layer.smooth: true

    color: Qt.rgba(0.06, 0.07, 0.10, 0.92)
    border.color: Qt.rgba(1, 1, 1, 0.15)
    border.width: 1

    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Video Telemetry (Stats for Nerds)"
                color: "#ff9500"
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                width: 22; height: 22; radius: 11
                color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                Canvas {
                    anchors.centerIn: parent
                    width: 10; height: 10
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
                MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.closeRequested() }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.1) }

        // Telemetry Data Grid
        GridLayout {
            columns: 2
            rowSpacing: 4
            columnSpacing: 16
            Layout.fillWidth: true

            Text { text: "Video Codec:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.videoCodec; color: "white"; font.pixelSize: 11; font.bold: true }

            Text { text: "Audio Codec:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.audioCodec; color: "white"; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight; Layout.maximumWidth: 260 }

            Text { text: "Hardware Decoder:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.hardwareDecoder; color: "#30d158"; font.pixelSize: 11; font.bold: true }

            Text { text: "Resolution & FPS:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.resolution + " @ " + playbackStats.frameRate; color: "white"; font.pixelSize: 11; font.family: "Monospace" }

            Text { text: "Color Space / HDR:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.colorSpace; color: "#0a84ff"; font.pixelSize: 11; font.bold: true }

            Text { text: "Frame Health:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.decodedFrames + " decoded / " + playbackStats.droppedFrames + " dropped"; color: playbackStats.droppedFrames > 0 ? "#ff9f0a" : "white"; font.pixelSize: 11; font.family: "Monospace" }

            Text { text: "Buffer Length:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.bufferHealth.toFixed(1) + " seconds forward"; color: "white"; font.pixelSize: 11; font.family: "Monospace" }

            Text { text: "Instantaneous Bitrate:"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11 }
            Text { text: playbackStats.currentBitrateMbps.toFixed(2) + " Mbps"; color: "#ff9500"; font.pixelSize: 11; font.bold: true; font.family: "Monospace" }
        }

        // Live Sparkline Bitrate Graph
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.45)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Canvas {
                id: sparklineCanvas
                anchors.fill: parent
                anchors.margins: 4

                Connections {
                    target: playbackStats
                    function onStatsUpdated() { sparklineCanvas.requestPaint(); }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var history = playbackStats.bitrateHistory;
                    if (history.length < 2) return;

                    var w = width;
                    var h = height;
                    var minVal = 20.0;
                    var maxVal = 70.0;

                    ctx.beginPath();
                    for (var i = 0; i < history.length; ++i) {
                        var x = (i / (history.length - 1)) * w;
                        var normY = (history[i] - minVal) / (maxVal - minVal);
                        var y = (1.0 - Math.max(0.0, Math.min(1.0, normY))) * h;
                        if (i === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }

                    ctx.strokeStyle = "#ff9500";
                    ctx.lineWidth = 1.5;
                    ctx.stroke();
                }
            }

            Text {
                text: "Live Bitrate History (30s)"
                color: Qt.rgba(1, 1, 1, 0.35)
                font.pixelSize: 9
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 6
            }
        }
    }
}

