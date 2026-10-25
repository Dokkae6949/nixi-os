import QtQuick
import QtQuick.Layouts
import ".."

BaseSurface {
    id: root

    property var actions: []
    property string pendingAction: ""
    property int confirmationDuration: 3500
    signal triggered(actionId: string)

    function reset(): void {
        pendingAction = "";
        confirmationTimeout.stop();
    }

    function activate(actionId: string): void {
        if (pendingAction !== actionId) {
            pendingAction = actionId;
            confirmationTimeout.restart();
            return;
        }
        reset();
        triggered(actionId);
    }

    implicitWidth: 230
    implicitHeight: menuContent.implicitHeight + Theme.spaceMd * 2
    radius: Theme.radiusPanel

    Timer {
        id: confirmationTimeout
        interval: root.confirmationDuration
        onTriggered: root.pendingAction = ""
    }

    ColumnLayout {
        id: menuContent
        anchors.fill: parent
        anchors.margins: Theme.spaceMd
        spacing: Theme.spaceXs

        Text {
            Layout.fillWidth: true
            text: root.pendingAction === "" ? "Power options" : "Click again to confirm"
            color: root.pendingAction === "" ? Theme.foregroundMuted : Theme.warning
            font.pixelSize: Theme.fontSmall
            font.weight: Theme.fontWeightMedium
        }

        Repeater {
            model: root.actions
            Rectangle {
                required property var modelData
                readonly property bool confirming: root.pendingAction === modelData.id
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.radiusSm
                color: confirming ? Theme.critical : actionHover.hovered ? Theme.surfaceRaised : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceSm
                    anchors.rightMargin: Theme.spaceSm
                    spacing: Theme.spaceSm
                    NixiIcon {
                        name: modelData.icon
                        size: Theme.iconSmall
                        color: confirming ? Theme.accentForeground : Theme.foreground
                    }
                    Text {
                        Layout.fillWidth: true
                        text: confirming ? "Confirm " + modelData.label.toLowerCase() : modelData.label
                        color: confirming ? Theme.accentForeground : Theme.foreground
                        font.pixelSize: Theme.fontBody
                        font.weight: confirming ? Theme.fontWeightMedium : Font.Normal
                    }
                }

                HoverHandler {
                    id: actionHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: root.activate(modelData.id)
                }
            }
        }
    }
}
