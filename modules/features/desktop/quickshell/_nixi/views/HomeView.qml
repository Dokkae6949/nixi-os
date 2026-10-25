import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    implicitWidth: content.implicitWidth + Theme.spaceLg * 2
    implicitHeight: Theme.homeHeight

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceLg
        anchors.rightMargin: Theme.spaceLg
        spacing: Theme.spaceSm

        Text {
            text: ClockService.time
            color: Theme.foreground
            font.pixelSize: Theme.fontBody + 2
            font.weight: Theme.fontWeightMedium
        }

        Text {
            text: ClockService.date
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontBody + 2
        }

        Item {
            implicitWidth: Theme.homeCenterGap
            Layout.fillWidth: true
        }

        NixiIcon {
            id: notificationBell
            name: NotificationStore.serverAvailable ? NotificationStore.doNotDisturb ? "notifications-off-symbolic" : NotificationStore.popupCount > 0 ? "notifications-active-symbolic" : "notification-symbolic" : "notification-important-symbolic"
            size: Theme.iconMedium

            Rectangle {
                visible: NotificationStore.unreadCount > 0
                width: 6
                height: 6
                radius: 3
                color: Theme.critical
                anchors.right: parent.right
                anchors.top: parent.top
            }

            TapHandler {
                enabled: NotificationStore.serverAvailable
                cursorShape: Qt.PointingHandCursor
                onTapped: ActionRegistry.run("open.notifications")
            }
        }

        WifiIcon {
            visible: NetworkService.wifiConnected
            connected: NetworkService.wifiConnected
            strength: NetworkService.wifiStrength
            size: Theme.iconMedium - 2
        }

        NixiIcon {
            visible: NetworkService.wiredConnected
            name: "network-wired-symbolic"
            size: Theme.iconMedium + 2
        }

        NixiIcon {
            visible: BluetoothService.enabled
            name: "bluetooth-symbolic"
            size: Theme.iconMedium + 2
        }

        PowerProfileIndicator {}

        BatteryIcon {
            visible: PowerService.available
            percent: PowerService.percent
            charging: PowerService.charging

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: SurfaceController.open(SurfaceController.Battery)
            }
        }
    }
}
