import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    required property string symbol
    required property string value

    implicitWidth: chipRow.implicitWidth + Theme.spaceSm * 2
    implicitHeight: 24
    radius: height / 2
    color: Theme.surfaceRaised

    RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: Theme.spaceXs
        Text {
            text: symbol
            color: Theme.accent
            font.pixelSize: Theme.fontSmall
            font.weight: Font.Bold
        }
        Text {
            text: value
            color: Theme.foreground
            font.pixelSize: Theme.fontSmall
        }
    }
}
