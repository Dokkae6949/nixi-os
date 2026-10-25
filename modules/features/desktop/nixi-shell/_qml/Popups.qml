import QtQuick
import Quickshell
import Quickshell.Wayland

// Notification popups, and the history list when the panel is open. Both live
// in one top-right surface that only exists while it has something to show.
PanelWindow {
    id: root

    readonly property bool center: Ui.panel === "notifications"

    visible: center || Notifs.popups.count > 0
    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.gap
        right: Theme.gap
    }
    implicitWidth: 400
    implicitHeight: Math.min(column.implicitHeight, (screen?.height ?? 1080) - 80)
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.namespace: "nixi-shell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: center ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    component Card: Rectangle {
        id: card
        required property int key
        required property string app
        required property string summary
        required property string body
        required property string icon
        required property string time
        required property bool critical
        required property int timeout
        readonly property bool hovered: hover.hovered

        width: column.width
        implicitHeight: content.implicitHeight + 20
        color: Theme.bg
        border.width: Theme.borderWidth
        border.color: critical ? Theme.red : hovered ? Theme.accent : Theme.border

        HoverHandler {
            id: hover
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: mouse => mouse.button === Qt.LeftButton ? Notifs.activate(card.key) : Notifs.dismiss(card.key)
        }
        Timer {
            running: !root.center && card.timeout > 0 && !card.hovered
            interval: card.timeout
            onTriggered: Notifs.hidePopup(card.key)
        }

        Row {
            id: content
            x: 10
            y: 10
            width: parent.width - 20
            spacing: 10

            Image {
                id: image
                visible: card.icon !== "" && status === Image.Ready
                width: visible ? 36 : 0
                height: 36
                source: card.icon
                sourceSize.width: 36
                sourceSize.height: 36
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Column {
                width: parent.width - (image.visible ? image.width + parent.spacing : 0)
                spacing: 2

                Text {
                    width: parent.width
                    text: card.app + "  " + card.time
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: card.summary
                    color: card.critical ? Theme.red : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                Text {
                    visible: text !== ""
                    width: parent.width
                    text: card.body
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    wrapMode: Text.Wrap
                    maximumLineCount: root.center ? 8 : 4
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight
        interactive: root.center && contentHeight > height
        clip: true

        Column {
            id: column
            width: root.width
            spacing: Theme.gap

            // History header.
            Rectangle {
                visible: root.center
                width: parent.width
                height: 32
                color: Theme.bg
                border.width: Theme.borderWidth
                border.color: Theme.accent
                focus: root.center
                Keys.onEscapePressed: Ui.panel = ""

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.count + " notifications" + (Notifs.dnd ? " · DND" : "")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Text {
                        text: Notifs.dnd ? "DND off" : "DND on"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Notifs.toggleDnd()
                        }
                    }
                    Text {
                        text: "Clear"
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Notifs.clearAll()
                        }
                    }
                }
            }

            Repeater {
                model: root.center ? Notifs.history : Notifs.popups
                Card {}
            }
        }
    }
}
