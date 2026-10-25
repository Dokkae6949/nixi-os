import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root
    readonly property var batteries: PowerService.laptopBatteries

    function duration(seconds): string {
        if (!seconds || seconds <= 0)
            return "estimating";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    implicitWidth: Theme.batteryViewWidth
    implicitHeight: batteries.length > 1 ? Theme.batteryViewTwoHeight : Theme.batteryViewOneHeight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceLg
        spacing: Theme.spaceSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            BatteryIcon {
                percent: PowerService.percent
                charging: PowerService.charging
                iconScale: 2
            }

            ColumnLayout {
                spacing: 0
                Text {
                    text: batteries.length > 1 ? "Combined power" : "Battery power"
                    color: Theme.foreground
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                }
                Text {
                    text: PowerService.charging
                          ? root.duration(PowerService.displayBattery.timeToFull) + " until full"
                          : root.duration(PowerService.displayBattery.timeToEmpty) + " remaining"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontBody
                }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 1
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: batteries.length + (batteries.length === 1 ? " pack" : " packs")
                    color: Theme.foreground
                    font.pixelSize: Theme.fontBody
                    font.weight: Theme.fontWeightMedium
                }
                Text {
                    text: "current / max / design"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusPanel
            color: Theme.surface
            border.width: 1
            border.color: Theme.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spaceMd
                spacing: 0

                Repeater {
                    model: root.batteries
                    Item {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        BatteryCard {
                            anchors.fill: parent
                            anchors.topMargin: index > 0 ? Theme.spaceSm : 0
                            anchors.bottomMargin: index < root.batteries.length - 1 ? Theme.spaceSm : 0
                            device: modelData
                            showBatteryIcon: root.batteries.length > 1
                        }

                        Rectangle {
                            visible: index > 0
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 1
                            color: Theme.outline
                        }
                    }
                }

                Text {
                    visible: root.batteries.length === 0
                    Layout.alignment: Qt.AlignCenter
                    text: "No laptop battery detected"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontBody
                }
            }
        }
    }
}
