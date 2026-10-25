import QtQuick
import Quickshell

// Wi-Fi, volume, brightness and battery in one floating pill, for screens
// without the bar. Each item hides itself when its service has nothing.
Rectangle {
    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.barHeight + 4
    color: Theme.bg1

    component Chip: Row {
        property string icon
        property string label
        property color tint
        spacing: 6
        anchors.verticalCenter: parent?.verticalCenter

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.icon
            color: parent.tint
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: parent.label !== ""
            width: Math.min(implicitWidth, 160)
            elide: Text.ElideRight
            text: parent.label
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: 16

        Chip {
            icon: Radio.icon
            label: Radio.label
            tint: Radio.link === null ? Theme.muted : Theme.blue
        }
        Chip {
            visible: Audio.hasSink
            icon: Audio.icon
            label: Audio.muted ? "" : Math.round(Audio.volume * 100) + "%"
            tint: Audio.muted ? Theme.muted : Theme.orange
        }
        Chip {
            visible: Sys.brightness >= 0
            icon: "\u{F00DF}"
            label: Math.round(Sys.brightness * 100) + "%"
            tint: Theme.yellow
        }
        Chip {
            visible: Battery.present
            icon: Battery.icon
            label: Battery.percent + "%"
            tint: Battery.tint
        }
    }
}
