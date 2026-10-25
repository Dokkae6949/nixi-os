import QtQuick
import ".."

Rectangle {
    id: root
    implicitWidth: 26
    implicitHeight: 26
    radius: height / 2
    color: hover.hovered ? Theme.surfaceRaised : "transparent"

    NixiIcon {
        anchors.centerIn: parent
        name: PowerService.profileIcon
        size: Theme.iconMedium
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: ActionRegistry.run("power.profile.cycle") }
}
