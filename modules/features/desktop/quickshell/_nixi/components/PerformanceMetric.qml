import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root
    required property string label
    required property string value
    required property string detail
    required property real ratio
    property color accentColor: Theme.accent

    implicitHeight: 46

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        ColumnLayout {
            Layout.preferredWidth: 150
            Layout.maximumWidth: 150
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.label
                color: Theme.foreground
                font.pixelSize: Theme.fontBody
                font.weight: Theme.fontWeightMedium
            }
            Text {
                Layout.fillWidth: true
                text: root.detail
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Theme.background
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.ratio))
                height: parent.height
                radius: parent.radius
                color: root.accentColor
                Behavior on width { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
            }
        }

        Text {
            Layout.preferredWidth: 54
            text: root.value
            color: root.accentColor
            font.pixelSize: Theme.fontBody + 2
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignRight
        }
    }
}
