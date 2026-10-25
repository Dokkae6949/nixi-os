import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

WlSessionLock {
    id: sessionLock
    locked: LockService.locked

    WlSessionLockSurface {
        id: lockSurface
        color: Theme.background

        readonly property var player: MediaService.playingPlayer
        property bool powerMenuOpen: false

        SystemClock {
            id: lockClock
            precision: SystemClock.Seconds
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background

            // Quiet depth without introducing a style foreign to the shell.
            Rectangle {
                width: Math.min(parent.width * 0.72, 900)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.top
                anchors.verticalCenterOffset: -width * 0.18
                radius: width / 2
                color: Theme.surface
                opacity: 0.32
            }

            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spaceXl
                spacing: Theme.spaceMd

                RowLayout {
                    spacing: Theme.spaceSm
                    NixiIcon {
                        name: NetworkService.wifiConnected ? "network-wireless-symbolic" : NetworkService.wiredConnected ? "network-wired-symbolic" : "network-wireless-offline-symbolic"
                        size: Theme.iconMedium
                        color: NetworkService.wifiConnected || NetworkService.wiredConnected ? Theme.foreground : Theme.foregroundMuted
                    }
                    Text {
                        text: NetworkService.wifiConnected ? "Wi-Fi" : NetworkService.wiredConnected ? "Wired" : "Offline"
                        color: Theme.foregroundMuted
                        font.pixelSize: Theme.fontBody
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    visible: PowerService.available
                    BatteryIcon {
                        percent: PowerService.percent
                        charging: PowerService.charging
                    }
                }

                IconButton {
                    iconName: "system-shutdown-symbolic"
                    accessibleName: "Power options"
                    active: lockSurface.powerMenuOpen
                    onClicked: {
                        lockSurface.powerMenuOpen = !lockSurface.powerMenuOpen;
                        powerMenu.reset();
                    }
                }
            }

            ConfirmationActionMenu {
                id: powerMenu
                visible: lockSurface.powerMenuOpen
                anchors.top: parent.top
                anchors.topMargin: Theme.spaceXl + Theme.controlSize + Theme.spaceSm
                anchors.right: parent.right
                anchors.rightMargin: Theme.spaceXl
                width: implicitWidth
                height: implicitHeight
                z: 20
                actions: ActionRegistry.select(["session.suspend", "session.logout", "session.reboot", "session.poweroff"])
                onTriggered: actionId => {
                    lockSurface.powerMenuOpen = false;
                    ActionRegistry.run(actionId);
                }
            }

            TransientPill {
                id: lockOsd
                anchors.top: parent.top
                anchors.topMargin: Theme.spaceLg
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.osdWidth
                height: Theme.homeHeight
                shown: SurfaceController.overlay === SurfaceController.StatusOsd
                z: 10

                StatusOsdView {
                    anchors.fill: parent
                }
            }

            TransientPill {
                id: lockBatteryNotification
                anchors.top: parent.top
                anchors.topMargin: Theme.spaceLg + Theme.homeHeight + Theme.spaceSm
                anchors.horizontalCenter: parent.horizontalCenter
                width: batteryCard.implicitWidth
                height: batteryCard.implicitHeight
                shown: BatteryWarnings.currentWarning !== null && NotificationPolicy.allows(NotificationPolicy.batteryChannel, NotificationPolicy.lockContext)
                z: 9

                NotificationCard {
                    id: batteryCard
                    anchors.fill: parent
                    source: BatteryWarnings.currentWarning
                    dismissible: false
                    expandable: false
                    interactive: false
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.max(72, parent.height * 0.105)
                spacing: Theme.spaceXs

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(lockClock.date, "HH:mm")
                    color: Theme.foreground
                    font.pixelSize: Math.max(64, Math.min(104, lockSurface.height * 0.105))
                    font.weight: Font.Light
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(lockClock.date, "dddd, d MMMM yyyy")
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontTitle
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Math.min(84, parent.height * 0.08)
                width: Math.min(430, parent.width - Theme.spaceXl * 2)

                BaseSurface {
                    Layout.fillWidth: true
                    implicitHeight: unlockContent.implicitHeight + Theme.spaceXl * 2
                    radius: Theme.radiusPanel

                    ColumnLayout {
                        id: unlockContent
                        anchors.fill: parent
                        anchors.margins: Theme.spaceXl
                        spacing: Theme.spaceMd

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spaceMd
                            Rectangle {
                                implicitWidth: 46
                                implicitHeight: 46
                                radius: 23
                                color: Theme.accent
                                NixiIcon {
                                    anchors.centerIn: parent
                                    name: "nixi-authentication-symbolic"
                                    color: Theme.accentForeground
                                    size: Theme.iconLarge
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: LockService.username
                                    color: Theme.foreground
                                    font.pixelSize: Theme.fontTitle
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: "Session locked"
                                    color: Theme.foregroundMuted
                                    font.pixelSize: Theme.fontSmall
                                }
                            }
                        }

                        TextEntry {
                            id: passwordField
                            Layout.fillWidth: true
                            placeholder: "Password"
                            password: true
                            inputEnabled: LockService.awaitingResponse
                            busyText: LockService.busy ? "Checking…" : ""
                            onAccepted: {
                                if (!LockService.awaitingResponse || text.length === 0)
                                    return;
                                const response = text;
                                clear();
                                LockService.submit(response);
                            }
                        }

                        Connections {
                            target: LockService
                            function onAwaitingResponseChanged(): void {
                                if (LockService.awaitingResponse)
                                    Qt.callLater(passwordField.focusInput);
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: LockService.statusMessage.length > 0
                            text: LockService.statusMessage
                            color: LockService.failed ? Theme.critical : Theme.foregroundMuted
                            font.pixelSize: Theme.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            visible: LockService.awaitingResponse && !LockService.failed
                            text: "Press Enter to unlock"
                            color: Theme.foregroundMuted
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }
            }

            RowLayout {
                visible: lockSurface.player !== null
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spaceXl
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, parent.width - Theme.spaceXl * 2)
                spacing: Theme.spaceSm

                NixiIcon {
                    name: "audio-x-generic-symbolic"
                    size: Theme.iconSmall
                    color: Theme.foregroundMuted
                }
                Text {
                    Layout.maximumWidth: Math.max(0, lockSurface.width - Theme.spaceXl * 2 - Theme.iconSmall - Theme.spaceSm)
                    text: lockSurface.player ? (lockSurface.player.trackTitle || "Unknown title") + "  ·  " + (lockSurface.player.trackArtist || lockSurface.player.identity) : ""
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }
            }
        }
    }
}
