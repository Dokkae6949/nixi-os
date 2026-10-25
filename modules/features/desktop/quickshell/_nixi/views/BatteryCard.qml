import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import ".."
import "../components"

Item {
    id: root
    required property var device
    property bool showBatteryIcon: true
    property real voltage: 0
    property real designCapacity: 0
    property int cycleCount: -1

    readonly property string sysfsPath: device.nativePath
                                                ? "/sys/class/power_supply/" + device.nativePath
                                                : ""
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property real fullCapacity: device.energyCapacity
    readonly property real currentEnergy: device.energy
    readonly property real reachableRatio: designCapacity > 0
                                           ? Math.max(0, Math.min(1, fullCapacity / designCapacity))
                                           : 1
    readonly property real storedRatio: designCapacity > 0
                                        ? Math.max(0, Math.min(1, currentEnergy / designCapacity))
                                        : reachableRatio * device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property string stateLabel: charging ? "charging"
                                         : device.state === UPowerDeviceState.PendingCharge ? "charge held"
                                         : device.state === UPowerDeviceState.FullyCharged ? "full"
                                         : device.state === UPowerDeviceState.Empty ? "empty"
                                         : device.state === UPowerDeviceState.Discharging ? "discharging"
                                         : "idle"
    readonly property color levelColor: charging ? Theme.positive
                                        : percent <= 20 ? Theme.critical
                                        : Theme.accent

    implicitHeight: 96

    FileView {
        id: voltageFile
        path: root.sysfsPath === "" ? "" : root.sysfsPath + "/voltage_now"
        onTextChanged: root.voltage = (Number(text().trim()) || 0) / 1000000
    }
    FileView {
        id: designFile
        path: root.sysfsPath === "" ? "" : root.sysfsPath + "/energy_full_design"
        onTextChanged: root.designCapacity = (Number(text().trim()) || 0) / 1000000
    }
    FileView {
        id: cycleFile
        path: root.sysfsPath === "" ? "" : root.sysfsPath + "/cycle_count"
        onTextChanged: {
            const value = Number(text().trim());
            root.cycleCount = isNaN(value) ? -1 : Math.round(value);
        }
    }
    Timer {
        interval: 15000
        repeat: true
        running: SurfaceController.content === SurfaceController.BatteryContent
        onTriggered: { voltageFile.reload(); designFile.reload(); cycleFile.reload(); }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            BatteryIcon {
                visible: root.showBatteryIcon
                percent: root.percent
                charging: root.charging
                iconScale: 1.3
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: root.device.model || root.device.nativePath || "Laptop battery"
                    color: Theme.foreground
                    font.pixelSize: Theme.fontBody
                    font.weight: Theme.fontWeightMedium
                    elide: Text.ElideRight
                }
                Text {
                    text: root.device.nativePath + "  ·  " + root.stateLabel
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 26

            Rectangle {
                id: capacityRail
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 12
                radius: 6
                color: Theme.background
                border.width: 1
                border.color: Theme.outline

                // Design capacity is the full dark rail. This lighter layer is
                // the maximum the aged pack can still reach.
                Rectangle {
                    width: parent.width * root.reachableRatio
                    height: parent.height
                    radius: parent.radius
                    color: Theme.foregroundMuted
                    opacity: 0.42
                    Behavior on width { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
                }

                // Stored energy is measured against design capacity too, so
                // both charge and battery wear are readable at a glance.
                Rectangle {
                    width: parent.width * root.storedRatio
                    height: parent.height
                    radius: parent.radius
                    color: root.levelColor
                    Behavior on width { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                Text {
                    text: root.currentEnergy.toFixed(1) + " Wh"
                    color: root.levelColor
                    font.pixelSize: 9
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.fullCapacity.toFixed(1) + " /  "
                          + (root.designCapacity > 0 ? root.designCapacity.toFixed(1) : "—") + " Wh"
                    color: Theme.foregroundMuted
                    font.pixelSize: 9
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            MetricChip { symbol: "V"; value: root.voltage > 0 ? root.voltage.toFixed(2) + " V" : "—" }
            MetricChip { symbol: "W"; value: root.device.changeRate > 0 ? root.device.changeRate.toFixed(1) + " W" : "idle" }
            MetricChip { symbol: "C"; value: root.cycleCount >= 0 ? root.cycleCount + " cycles" : "—" }
            Item { Layout.fillWidth: true }
        }
    }
}
