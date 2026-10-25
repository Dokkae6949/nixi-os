import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import ".."
import "../components"

Item {
    id: root

    onEnabledChanged: BluetoothService.setDiscovering(enabled)

    Connections {
        target: BluetoothService
        function onEnabledChanged(): void {
            BluetoothService.setDiscovering(root.enabled);
        }
    }

    Connections {
        target: BluetoothPairingService
        function onPromptTypeChanged(): void {
            if (BluetoothPairingService.promptType === "pin" || BluetoothPairingService.promptType === "passkey")
                Qt.callLater(pairingCode.focusInput);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        ConnectivityHeader {
            Layout.fillWidth: true
            title: "Bluetooth"
            subtitle: BluetoothService.adapter === null ? "No adapter available" : BluetoothService.adapter.discovering ? "Discovering nearby devices…" : BluetoothService.enabled ? "Choose a device" : "Bluetooth is off"
            iconName: "bluetooth-symbolic"
            radioEnabled: BluetoothService.enabled
            radioAvailable: BluetoothService.adapter !== null && BluetoothService.adapter.state !== BluetoothAdapterState.Blocked
            onToggled: BluetoothService.toggle()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusPanel
            color: Theme.surfaceRaised
            clip: true

            ListView {
                id: deviceList
                anchors.fill: parent
                anchors.margins: Theme.spaceSm
                spacing: Theme.spaceXs
                clip: true
                model: BluetoothService.enabled ? BluetoothService.devices : []
                onCountChanged: if (count > 0 && currentIndex < 0)
                    currentIndex = 0

                delegate: Rectangle {
                    id: deviceRow
                    required property var modelData
                    width: ListView.view.width
                    height: 58
                    radius: Theme.radiusSm
                    color: modelData.connected ? Theme.background : ListView.isCurrentItem || rowHover.hovered ? Theme.surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spaceMd
                        anchors.rightMargin: Theme.spaceMd
                        spacing: Theme.spaceMd

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 18
                            color: modelData.connected ? Theme.accent : Theme.surfaceRaised
                            NixiIcon {
                                anchors.centerIn: parent
                                name: BluetoothService.deviceIcon(modelData)
                                fallbackName: "bluetooth-symbolic"
                                size: Theme.iconMedium
                                color: modelData.connected ? Theme.accentForeground : Theme.foreground
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: BluetoothService.displayName(modelData)
                                color: Theme.foreground
                                font.pixelSize: Theme.fontBody
                                font.weight: modelData.connected ? Font.Bold : Theme.fontWeightMedium
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.pairing ? "Pairing…" : modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : modelData.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…" : (modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available") + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "% battery" : "") + (!BluetoothService.hasFriendlyName(modelData) ? " · " + modelData.address : "")
                                color: modelData.connected ? Theme.accent : Theme.foregroundMuted
                                font.pixelSize: Theme.fontSmall
                            }
                        }

                        DismissButton {
                            visible: modelData.paired && !modelData.connected
                            Layout.preferredWidth: visible ? 30 : 0
                            Layout.preferredHeight: 30
                            onClicked: modelData.forget()
                        }
                        NixiIcon {
                            name: modelData.connected ? "window-close-symbolic" : "media-playback-start-symbolic"
                            size: Theme.iconSmall
                            color: Theme.foregroundMuted
                        }
                    }

                    HoverHandler {
                        id: rowHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered)
                            deviceList.currentIndex = index
                    }
                    TapHandler {
                        onTapped: BluetoothService.activate(modelData)
                    }
                }

                WheelHandler {
                    target: deviceList
                }

                Text {
                    anchors.centerIn: parent
                    visible: deviceList.count === 0
                    text: BluetoothService.enabled ? "Searching for nearby devices…" : "Turn on Bluetooth to discover devices"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontBody
                }
            }

            ListNavigation {
                list: deviceList
                active: root.enabled && !BluetoothPairingService.active
                onActivated: index => BluetoothService.activate(deviceList.model[index])
            }
        }
    }

    Rectangle {
        visible: BluetoothPairingService.active
        anchors.fill: parent
        color: "#99000000"
        z: 10

        BaseSurface {
            anchors.centerIn: parent
            width: Math.min(410, parent.width - Theme.spaceXl * 2)
            height: pairingContent.implicitHeight + Theme.spaceXl * 2
            radius: Theme.radiusPanel

            ColumnLayout {
                id: pairingContent
                anchors.fill: parent
                anchors.margins: Theme.spaceXl
                spacing: Theme.spaceMd

                Text {
                    Layout.fillWidth: true
                    text: "Pair " + (BluetoothPairingService.device ? BluetoothPairingService.device.name || BluetoothPairingService.device.deviceName || BluetoothPairingService.device.address : "device")
                    color: Theme.foreground
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: BluetoothPairingService.promptText !== "" ? BluetoothPairingService.promptText : BluetoothPairingService.error !== "" ? BluetoothPairingService.error : "Waiting for the device…"
                    color: BluetoothPairingService.error !== "" ? Theme.critical : Theme.foregroundMuted
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.Wrap
                }
                Text {
                    visible: BluetoothPairingService.displayedCode !== ""
                    Layout.alignment: Qt.AlignHCenter
                    text: BluetoothPairingService.displayedCode
                    color: Theme.accent
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: 4
                }
                TextEntry {
                    id: pairingCode
                    visible: BluetoothPairingService.promptType === "pin" || BluetoothPairingService.promptType === "passkey"
                    Layout.fillWidth: true
                    placeholder: BluetoothPairingService.promptType === "pin" ? "PIN" : "Passkey"
                    password: BluetoothPairingService.promptType === "pin"
                    onAccepted: {
                        BluetoothPairingService.submit(text);
                        clear();
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Item {
                        Layout.fillWidth: true
                    }
                    ActionButton {
                        label: "Cancel"
                        onClicked: BluetoothPairingService.cancel()
                    }
                    ActionButton {
                        visible: BluetoothPairingService.promptType === "confirm" || BluetoothPairingService.promptType === "authorize"
                        label: "Reject"
                        danger: true
                        onClicked: BluetoothPairingService.reject()
                    }
                    ActionButton {
                        visible: BluetoothPairingService.promptType === "confirm" || BluetoothPairingService.promptType === "authorize"
                        label: "Allow"
                        accent: true
                        onClicked: BluetoothPairingService.accept()
                    }
                    ActionButton {
                        visible: pairingCode.visible
                        label: "Continue"
                        accent: true
                        enabled: pairingCode.text !== ""
                        onClicked: {
                            BluetoothPairingService.submit(pairingCode.text);
                            pairingCode.clear();
                        }
                    }
                }
            }
        }
    }
}
