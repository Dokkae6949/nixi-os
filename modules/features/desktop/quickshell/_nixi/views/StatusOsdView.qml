import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceLg
        anchors.rightMargin: Theme.spaceLg
        spacing: Theme.spaceLg

        NixiIcon {
            name: PopupController.osdIcon
            size: Theme.iconLarge
        }

        Rectangle {
            visible: PopupController.osdKind === "level"
            Layout.fillWidth: true
            implicitHeight: 8
            radius: height / 2
            color: Theme.surfaceRaised

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, PopupController.osdValue))
                height: parent.height
                radius: parent.radius
                color: Theme.accent
                Behavior on width {
                    NumberAnimation { duration: Motion.fast; easing.type: Motion.easing }
                }
            }
        }

        Text {
            visible: PopupController.osdKind === "status"
            Layout.fillWidth: true
            text: PopupController.osdValue > 0 ? "Enabled" : "Disabled"
            color: PopupController.osdValue > 0 ? Theme.accent : Theme.foregroundMuted
            font.pixelSize: Theme.fontBody + 2
            font.weight: Theme.fontWeightMedium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ColumnLayout {
            visible: PopupController.osdKind === "message"
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: PopupController.osdLabel
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontSmall
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                text: PopupController.osdText
                color: Theme.accent
                font.pixelSize: Theme.fontBody + 2
                font.weight: Theme.fontWeightMedium
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
