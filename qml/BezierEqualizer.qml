import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    implicitWidth: 380
    implicitHeight: 260

    // GPU Scenegraph texture caching for 0% CPU rendering when static [Change 12]
    layer.enabled: true
    layer.smooth: true

    signal bandGainChanged(int bandIndex, real gainDb)

    // 10 Standard ISO Audio Frequency bands
    property var bandFrequencies: [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    property var bandLabels: ["31Hz", "63Hz", "125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz", "16kHz"]
    
    // Normalized gains from -20dB to +20dB, stored as normalized -1.0 to +1.0
    // Default preset with slight warm bass boost & crystal highs
    property var gains: [0.35, 0.25, 0.10, -0.05, 0.0, 0.05, 0.15, 0.20, 0.30, 0.25]

    function setPreset(presetName) {
        if (presetName === "Flat") {
            root.gains = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        } else if (presetName === "Bass Boost") {
            root.gains = [0.65, 0.50, 0.35, 0.15, 0, 0, 0, 0, 0, 0];
        } else if (presetName === "Vocal Clarity") {
            root.gains = [-0.2, -0.1, 0, 0.2, 0.45, 0.40, 0.3, 0.15, 0.05, 0];
        } else if (presetName === "Rock") {
            root.gains = [0.45, 0.30, 0.10, -0.10, -0.05, 0.10, 0.25, 0.35, 0.40, 0.45];
        }
        canvas.requestPaint();
    }

    Rectangle {
        id: graphBg
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(0.06, 0.07, 0.10, 0.85)
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        // Horizontal Decibel Grid Lines
        Repeater {
            model: [-12, -6, 0, 6, 12]
            Rectangle {
                width: parent.width - 24
                height: 1
                x: 12
                y: {
                    var norm = (modelData + 20) / 40.0;
                    return (1.0 - norm) * (graphBg.height - 40) + 20;
                }
                color: modelData === 0 ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    text: (modelData > 0 ? "+" : "") + modelData + " dB"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font.pixelSize: 9
                    font.family: "Monospace"
                    anchors.right: parent.right
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 1
                }
            }
        }

        // Canvas for Smooth Bezier Curve Rendering
        Canvas {
            id: canvas
            anchors.fill: parent
            anchors.margins: 14
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                var w = width;
                var h = height;
                var numBands = root.bandFrequencies.length;

                // Calculate control points
                var pts = [];
                for (var i = 0; i < numBands; ++i) {
                    var x = (i / (numBands - 1)) * w;
                    // Normalized gain from -1.0 to 1.0 mapped to canvas Y
                    var normY = (root.gains[i] + 1.0) / 2.0; // 0.0 to 1.0
                    var y = (1.0 - normY) * h;
                    pts.push({ x: x, y: y });
                }

                // 1. Draw glowing gradient fill under the curve
                ctx.beginPath();
                ctx.moveTo(pts[0].x, h);
                ctx.lineTo(pts[0].x, pts[0].y);

                for (var k = 0; k < pts.length - 1; ++k) {
                    var cp1x = pts[k].x + (pts[k + 1].x - pts[k].x) / 2;
                    var cp1y = pts[k].y;
                    var cp2x = pts[k].x + (pts[k + 1].x - pts[k].x) / 2;
                    var cp2y = pts[k + 1].y;
                    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, pts[k + 1].x, pts[k + 1].y);
                }

                ctx.lineTo(pts[pts.length - 1].x, h);
                ctx.closePath();

                var fillGrad = ctx.createLinearGradient(0, 0, 0, h);
                fillGrad.addColorStop(0.0, "rgba(255, 149, 0, 0.35)");
                fillGrad.addColorStop(0.6, "rgba(255, 149, 0, 0.12)");
                fillGrad.addColorStop(1.0, "rgba(255, 149, 0, 0.0)");
                ctx.fillStyle = fillGrad;
                ctx.fill();

                // 2. Stroke the primary Bezier line
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                for (var j = 0; j < pts.length - 1; ++j) {
                    var c1x = pts[j].x + (pts[j + 1].x - pts[j].x) / 2;
                    var c1y = pts[j].y;
                    var c2x = pts[j].x + (pts[j + 1].x - pts[j].x) / 2;
                    var c2y = pts[j + 1].y;
                    ctx.bezierCurveTo(c1x, c1y, c2x, c2y, pts[j + 1].x, pts[j + 1].y);
                }

                ctx.strokeStyle = "#ff9500";
                ctx.lineWidth = 3;
                ctx.stroke();
            }
        }

        // Draggable Control Handles
        Repeater {
            model: 10
            delegate: Rectangle {
                id: handle
                width: 14
                height: 14
                radius: 7

                x: 14 + (index / 9) * (graphBg.width - 28) - (width / 2)
                y: {
                    var normY = (root.gains[index] + 1.0) / 2.0;
                    return 14 + (1.0 - normY) * (graphBg.height - 28) - (height / 2);
                }

                color: dragHandleArea.containsMouse ? "#ffffff" : "#ff9500"
                border.color: "#ffffff"
                border.width: 2

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: dragHandleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeVerCursor
                    drag.target: handle
                    drag.axis: Drag.YAxis
                    drag.minimumY: 14 - (handle.height / 2)
                    drag.maximumY: graphBg.height - 14 - (handle.height / 2)

                    onPositionChanged: {
                        if (drag.active) {
                            var relY = handle.y + (handle.height / 2) - 14;
                            var ratio = 1.0 - (relY / (graphBg.height - 28)); // 0.0 to 1.0
                            var newGainNorm = Math.max(-1.0, Math.min(1.0, ratio * 2.0 - 1.0));
                            
                            var gainsCopy = root.gains.slice();
                            gainsCopy[index] = newGainNorm;
                            root.gains = gainsCopy;

                            var gainDb = newGainNorm * 20.0;
                            root.bandGainChanged(index, gainDb);
                            canvas.requestPaint();
                        }
                    }

                    onDoubleClicked: {
                        var gainsCopy = root.gains.slice();
                        gainsCopy[index] = 0.0;
                        root.gains = gainsCopy;
                        root.bandGainChanged(index, 0.0);
                        canvas.requestPaint();
                    }
                }

                // Frequency Label Below
                Text {
                    text: root.bandLabels[index]
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }
    }
}

