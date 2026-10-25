import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    function size(bytes): string {
        if (bytes >= 1099511627776)
            return (bytes / 1099511627776).toFixed(1) + " TiB";
        if (bytes >= 1073741824)
            return (bytes / 1073741824).toFixed(1) + " GiB";
        return (bytes / 1048576).toFixed(0) + " MiB";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceLg
        spacing: Theme.spaceMd

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "System"
                color: Theme.foreground
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: profileRow.implicitWidth + Theme.spaceMd * 2
                implicitHeight: 30
                radius: height / 2
                color: profileHover.hovered ? Theme.surfaceRaised : Theme.background

                RowLayout {
                    id: profileRow
                    anchors.centerIn: parent
                    spacing: Theme.spaceSm
                    NixiIcon { name: PowerService.profileIcon; size: Theme.iconSmall }
                    Text {
                        text: PowerService.profileLabel
                        color: Theme.foreground
                        font.pixelSize: Theme.fontSmall
                        font.weight: Theme.fontWeightMedium
                    }
                }
                HoverHandler { id: profileHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: ActionRegistry.run("power.profile.cycle") }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusPanel
            color: Theme.surfaceRaised

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceLg
                anchors.rightMargin: Theme.spaceLg
                anchors.topMargin: Theme.spaceSm
                anchors.bottomMargin: Theme.spaceSm
                spacing: 0

                PerformanceMetric {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label: "CPU"
                    value: Math.round(SystemMetrics.cpuLoad * 100) + "%"
                    detail: "total load"
                    ratio: SystemMetrics.cpuLoad
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline }
                PerformanceMetric {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label: "Memory"
                    value: Math.round(SystemMetrics.memoryLoad * 100) + "%"
                    detail: root.size(SystemMetrics.memoryUsed) + " of " + root.size(SystemMetrics.memoryTotal)
                    ratio: SystemMetrics.memoryLoad
                    accentColor: Theme.positive
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline }
                PerformanceMetric {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label: "Storage"
                    value: Math.round(SystemMetrics.storageLoad * 100) + "%"
                    detail: root.size(SystemMetrics.storageUsed) + " of " + root.size(SystemMetrics.storageTotal) + " · root"
                    ratio: SystemMetrics.storageLoad
                    accentColor: Theme.warning
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.outline }
                PerformanceMetric {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label: "Temperature"
                    value: SystemMetrics.temperature > 0 ? Math.round(SystemMetrics.temperature) + "°" : "—"
                    detail: SystemMetrics.temperature > 0 ? SystemMetrics.temperatureSource : "No readable sensor"
                    ratio: SystemMetrics.temperature > 0 ? SystemMetrics.temperature / 100 : 0
                    accentColor: SystemMetrics.temperature >= 85 ? Theme.critical : Theme.warning
                }
            }
        }
    }
}
