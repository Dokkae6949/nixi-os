import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland

// Left: workspaces and the focused window. Center: clock. Right: status
// grouped into pills (system, network, audio and display, battery,
// notifications). Every module has a fixed icon colour so it can be found at a
// glance; red and yellow are reserved for states that need attention.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.borderWidth
    color: Theme.bg
    WlrLayershell.namespace: "nixi-shell-bar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // A coloured icon with an optional value; reacts to clicks and the wheel.
    component Mod: Item {
        id: mod
        property string icon
        property string label
        property color tint: Theme.fg
        property color labelColor: Theme.fg
        property int maxLabelWidth: 0
        signal clicked(int button)
        signal scrolled(bool up)

        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        anchors.verticalCenter: parent?.verticalCenter

        Row {
            id: row
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: mod.icon
                color: mod.tint
                font.family: Theme.font
                font.pixelSize: Theme.iconSize
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: mod.label !== ""
                width: mod.maxLabelWidth > 0 ? Math.min(implicitWidth, mod.maxLabelWidth) : implicitWidth
                text: mod.label
                color: mod.labelColor
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: mouse => mod.clicked(mouse.button)
            onWheel: wheel => mod.scrolled(wheel.angleDelta.y > 0)
        }
    }

    // A group of modules on a raised background.
    component Pill: Rectangle {
        default property alias items: row.data
        implicitWidth: row.implicitWidth + 20
        height: Theme.barHeight - 6
        anchors.verticalCenter: parent?.verticalCenter
        color: Theme.bg1

        Row {
            id: row
            anchors.centerIn: parent
            height: parent.height
            spacing: 14
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.borderWidth
        color: Theme.border
    }

    Item {
        anchors.fill: parent
        anchors.bottomMargin: Theme.borderWidth
        anchors.leftMargin: 3
        anchors.rightMargin: 3

        // Left: workspaces and focused window.
        Row {
            id: left
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap * 2

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                    model: Niri.workspaces.filter(w => !bar.screen || w.output === bar.screen.name)

                    Rectangle {
                        required property var modelData
                        readonly property bool occupied: modelData.active_window_id !== null
                        width: Math.max(Theme.barHeight - 4, label.implicitWidth + 12)
                        height: Theme.barHeight - 6
                        color: modelData.is_active ? Theme.accent : occupied ? Theme.bg1 : "transparent"

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData.name || parent.modelData.idx
                            color: parent.modelData.is_active ? Theme.bg : parent.occupied ? Theme.fg : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.bold: parent.modelData.is_active
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Niri.focusWorkspace(parent.modelData.idx)
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, Math.max(0, center.x - left.x - x - Theme.gap * 4))
                text: Niri.title
                elide: Text.ElideRight
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }

        // Center: time, then the date in a quieter colour.
        Item {
            id: center
            anchors.centerIn: parent
            width: clockRow.implicitWidth
            height: parent.height

            Row {
                id: clockRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "ddd d MMM")
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Ui.toggle("notifications")
            }
        }

        // Right: status.
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: Theme.gap

            // System: load, memory, power profile.
            Pill {
                Mod {
                    icon: "\u{F0EE0}"
                    label: Sys.cpu + "%"
                    tint: Sys.cpu >= 90 ? Theme.yellow : Theme.aqua
                    onClicked: Session.run(["alacritty", "-e", "btop"])
                }
                Mod {
                    icon: "\u{F035B}"
                    label: Sys.mem + "%"
                    tint: Sys.mem >= 90 ? Theme.yellow : Theme.aqua
                    onClicked: Session.run(["alacritty", "-e", "btop"])
                }
                Mod {
                    // leaf / scale / speedometer
                    icon: Sys.profile === PowerProfile.PowerSaver ? "\u{F032A}" : Sys.profile === PowerProfile.Performance ? "\u{F04C5}" : "\u{F05D1}"
                    tint: Sys.profile === PowerProfile.PowerSaver ? Theme.green : Sys.profile === PowerProfile.Performance ? Theme.yellow : Theme.aqua
                    onClicked: Sys.cycleProfile()
                }
            }

            // Network: Wi-Fi/Ethernet and Bluetooth.
            Pill {
                Mod {
                    icon: Radio.icon
                    label: Radio.label
                    maxLabelWidth: 140
                    tint: Radio.link === null ? Theme.muted : Theme.blue
                    labelColor: Radio.link === null ? Theme.muted : Theme.fg
                    onClicked: button => {
                        if (button === Qt.RightButton)
                            Radio.toggleWifi();
                        else
                            Session.run(["alacritty", "-e", "nmtui"]);
                    }
                }
                Mod {
                    visible: Radio.adapter !== null
                    icon: !Radio.btEnabled ? "\u{F00B2}" : Radio.btConnected.length > 0 ? "\u{F00B1}" : "\u{F00AF}"
                    label: Radio.btConnected.length === 1 ? Radio.btNames : Radio.btConnected.length > 1 ? String(Radio.btConnected.length) : ""
                    maxLabelWidth: 120
                    tint: Radio.btEnabled ? Theme.blue : Theme.muted
                    onClicked: Radio.toggleBluetooth()
                }
            }

            // Audio and display: microphone (only when muted), volume, brightness.
            Pill {
                visible: Audio.hasSink || Sys.brightness >= 0
                Mod {
                    visible: Audio.hasMic && Audio.micMuted
                    icon: "\u{F036D}"
                    tint: Theme.red
                    onClicked: Audio.toggleMic()
                }
                Mod {
                    visible: Audio.hasSink
                    icon: Audio.muted ? "\u{F0581}" : Audio.volume >= 0.66 ? "\u{F057E}" : Audio.volume >= 0.33 ? "\u{F0580}" : "\u{F057F}"
                    label: Audio.muted ? "mute" : Math.round(Audio.volume * 100) + "%"
                    tint: Audio.muted ? Theme.muted : Theme.orange
                    labelColor: Audio.muted ? Theme.muted : Theme.fg
                    onClicked: button => button === Qt.RightButton ? Audio.toggleMic() : Audio.toggleMute()
                    onScrolled: up => Audio.stepVolume(up ? 5 : -5)
                }
                Mod {
                    visible: Sys.brightness >= 0
                    icon: "\u{F00DF}"
                    label: Math.round(Sys.brightness * 100) + "%"
                    tint: Theme.yellow
                    onScrolled: up => Sys.stepBrightness(up ? 5 : -5)
                }
            }

            // Battery.
            Pill {
                visible: Battery.present
                Mod {
                    visible: Battery.present
                    readonly property string eta: Battery.duration(Battery.seconds)
                    icon: Battery.icon
                    label: Battery.percent + "%" + (eta ? " · " + eta : "")
                    tint: Battery.tint
                    labelColor: Battery.low ? Theme.red : Theme.fg
                    onClicked: Battery.report()
                }
            }

            // Notifications.
            Pill {
                Mod {
                    icon: Notifs.dnd ? "\u{F009B}" : Notifs.count > 0 ? "\u{F009E}" : "\u{F009C}"
                    label: Notifs.count > 0 ? String(Notifs.count) : ""
                    tint: Notifs.dnd ? Theme.muted : Notifs.count > 0 ? Theme.accent : Theme.fg
                    onClicked: button => {
                        if (button === Qt.RightButton)
                            Notifs.toggleDnd();
                        else
                            Ui.toggle("notifications");
                    }
                }
            }
        }
    }
}
