import QtQuick
import ".."

Rectangle {
    id: root
    property alias text: label.text
    implicitWidth: Math.max(18, label.implicitWidth + 8)
    implicitHeight: 18
    radius: height / 2
    color: Theme.accent

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.accentForeground
        font.pixelSize: 10
        font.weight: Font.Bold
    }
}
