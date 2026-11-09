import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    implicitWidth: 320
    implicitHeight: 80

    // GPU layer caching
    layer.enabled: true
    layer.smooth: true

    Row {
        anchors.fill: parent
        spacing: 3

        Repeater {
            model: audioVisualizer.spectrumBars.length

            Rectangle {
                width: (root.width - (audioVisualizer.spectrumBars.length - 1) * 3) / audioVisualizer.spectrumBars.length
                height: Math.max(4, audioVisualizer.spectrumBars[index] * root.height)
                anchors.bottom: parent.bottom
                radius: 2

                // Dynamic gradient from cyan to amber based on frequency height
                color: {
                    var val = audioVisualizer.spectrumBars[index];
                    if (val > 0.8) return "#ff3b30";
                    if (val > 0.5) return "#ff9500";
                    return "#0a84ff";
                }

                Behavior on height { NumberAnimation { duration: 32 } }
                Behavior on color { ColorAnimation { duration: 60 } }
            }
        }
    }
}

