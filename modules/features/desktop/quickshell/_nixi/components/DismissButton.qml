import QtQuick
import ".."

Rectangle {
    id: root
    signal clicked
    property color hoverColor: Theme.surfaceRaised
    property real buttonSize: 30

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    radius: buttonSize / 2
    color: hover.hovered ? hoverColor : "transparent"

    Text {
        anchors.centerIn: parent
        text: "×"
        color: Theme.foregroundMuted
        font.pixelSize: root.buttonSize * 0.72
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
}
