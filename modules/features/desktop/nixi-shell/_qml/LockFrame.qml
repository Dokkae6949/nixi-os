import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The shared look of the lock screen and the greeter: a big clock with the
// date under it, status chips floating top right, the now-playing track at
// the bottom. Children go under the date (the form); `corner` items sit
// bottom right.
Rectangle {
    id: root

    default property alias form: formSlot.data
    property alias corner: cornerSlot.data
    // Only one output needs the form; the others just show the time.
    property bool primary: true

    color: Theme.bgHard

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? null

    StatusChips {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 16
    }

    // Anchored by its bottom so the form can grow downwards without moving it.
    Column {
        id: header
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: 20
        spacing: 0

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: Qt.formatDateTime(clock.date, "HH")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 168
                font.bold: true
            }
            Text {
                text: ":"
                color: Theme.accent
                opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.35
                font.family: Theme.font
                font.pixelSize: 168
                font.bold: true

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
            Text {
                text: Qt.formatDateTime(clock.date, "mm")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 168
                font.bold: true
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 22
        }
    }

    Item {
        id: formSlot
        visible: root.primary
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.topMargin: 56
        width: childrenRect.width
        height: childrenRect.height
    }

    Row {
        visible: root.player !== null
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        spacing: 8

        Text {
            text: "\u{F075A}"
            color: Theme.aqua
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
        }
        Text {
            width: Math.min(implicitWidth, 520)
            elide: Text.ElideRight
            text: root.player ? [root.player.trackArtist, root.player.trackTitle].filter(s => s).join(" — ") : ""
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    Row {
        id: cornerSlot
        visible: root.primary
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 16
        spacing: Theme.gap
    }
}
