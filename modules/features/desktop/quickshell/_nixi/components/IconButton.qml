import QtQuick
import ".."

Rectangle {
    id: root
    property alias iconName: icon.name
    property bool active: false
    property string accessibleName: ""
    signal clicked

    implicitWidth: Theme.controlSize
    implicitHeight: Theme.controlSize
    radius: width / 2
    color: active ? Theme.accent : (mouse.containsMouse ? Theme.surfaceRaised : "transparent")

    Behavior on color { ColorAnimation { duration: Motion.fast } }

    NixiIcon {
        id: icon
        anchors.centerIn: parent
        size: Theme.iconMedium
        color: root.active ? Theme.accentForeground : Theme.foreground
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
