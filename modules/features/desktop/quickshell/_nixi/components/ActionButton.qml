import QtQuick
import ".."

Rectangle {
    id: root
    property string label: ""
    property bool accent: false
    property bool danger: false
    signal clicked

    implicitWidth: buttonLabel.implicitWidth + Theme.spaceMd * 2
    implicitHeight: Theme.controlSize
    radius: Theme.radiusSm
    color: !enabled ? Theme.surfaceRaised : danger ? Theme.critical : accent ? Theme.accent : hover.hovered ? Theme.surfaceRaised : "transparent"
    border.width: accent || danger ? 0 : 1
    border.color: Theme.outline
    opacity: enabled ? 1 : 0.55

    Text {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.label
        color: root.accent || root.danger ? Theme.accentForeground : Theme.foreground
        font.pixelSize: Theme.fontBody
        font.weight: Theme.fontWeightMedium
    }
    HoverHandler {
        id: hover
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
