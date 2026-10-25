import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property bool radioEnabled: false
    property bool radioAvailable: true
    signal toggled

    spacing: Theme.spaceMd

    Rectangle {
        implicitWidth: 42
        implicitHeight: 42
        radius: 21
        color: root.radioEnabled ? Theme.accent : Theme.surfaceRaised
        NixiIcon {
            anchors.centerIn: parent
            name: root.iconName
            size: Theme.iconLarge
            color: root.radioEnabled ? Theme.accentForeground : Theme.foregroundMuted
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
            text: root.title
            color: Theme.foreground
            font.pixelSize: Theme.fontTitle
            font.weight: Font.Bold
        }
        Text {
            Layout.fillWidth: true
            text: root.subtitle
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }
    }
    Rectangle {
        implicitWidth: 48
        implicitHeight: 26
        radius: 13
        color: root.radioEnabled ? Theme.accent : Theme.surfaceRaised
        opacity: root.radioAvailable ? 1 : 0.5
        Rectangle {
            width: 20
            height: 20
            radius: 10
            anchors.verticalCenter: parent.verticalCenter
            x: root.radioEnabled ? parent.width - width - 3 : 3
            color: root.radioEnabled ? Theme.accentForeground : Theme.foregroundMuted
            Behavior on x {
                NumberAnimation {
                    duration: Motion.fast
                    easing.type: Motion.easing
                }
            }
        }
        HoverHandler {
            enabled: root.radioAvailable
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            enabled: root.radioAvailable
            onTapped: root.toggled()
        }
    }
}
