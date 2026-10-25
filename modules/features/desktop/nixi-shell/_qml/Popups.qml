import QtQuick
import Quickshell
import Quickshell.Wayland

// Notification popups, and the history list when the panel is open. Both live
// in one top-right surface that only exists while it has something to show.
PanelWindow {
    id: root

    readonly property bool center: Ui.panel === "notifications"

    // Each opening starts on the newest entry.
    onCenterChanged: {
        if (center) {
            Notifs.selected = 0;
            flick.contentY = 0;
        }
    }

    // Scroll just enough to keep the selected history row in view.
    function reveal(): void {
        const item = cards.itemAt(Notifs.selected);
        if (!root.center || !item)
            return;
        if (Notifs.selected === 0)
            flick.contentY = 0;
        else if (item.y < flick.contentY)
            flick.contentY = item.y;
        else if (item.y + item.height > flick.contentY + flick.height)
            flick.contentY = item.y + item.height - flick.height;
    }

    Connections {
        target: Notifs
        function onSelectedChanged(): void {
            root.reveal();
        }
    }

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
    WlrLayershell.keyboardFocus: center ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    component Card: Rectangle {
        id: card
        required property int index
        required property int key
        required property string app
        required property string summary
        required property string body
        required property string icon
        required property string time
        required property bool critical
        required property int timeout
        readonly property bool hovered: hover.hovered
        readonly property bool selected: root.center && index === Notifs.selected

        width: column.width
        implicitHeight: content.implicitHeight + 20
        color: selected ? Theme.bg1 : Theme.bg
        border.width: Theme.borderWidth
        border.color: critical ? Theme.red : hovered || selected ? Theme.accent : Theme.border

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
        id: flick
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
                // Same keys as the launcher list.
                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    const shift = event.modifiers & Qt.ShiftModifier;
                    if (event.key === Qt.Key_Escape) {
                        Ui.panel = "";
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_J || (ctrl && event.key === Qt.Key_N)) {
                        Notifs.select(1);
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || event.key === Qt.Key_K || (ctrl && event.key === Qt.Key_P)) {
                        Notifs.select(-1);
                    } else if (event.key === Qt.Key_Home) {
                        Notifs.selected = 0;
                    } else if (event.key === Qt.Key_End) {
                        Notifs.selected = Math.max(0, Notifs.count - 1);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        Notifs.activateSelected();
                    } else if ((event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) && shift) {
                        Notifs.clearAll();
                    } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                        Notifs.dismissSelected();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

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
                id: cards
                model: root.center ? Notifs.history : Notifs.popups
                Card {}
            }
        }
    }
}
