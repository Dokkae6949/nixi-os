import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property alias text: editor.text
    property alias editor: editor
    property string placeholder: ""
    property string busyText: ""
    property string leadingIcon: ""
    property bool password: false
    property bool inputEnabled: true
    property bool selectByMouse: true
    readonly property bool busy: busyText !== ""

    signal edited(text: string)
    signal accepted
    signal escapePressed
    signal keyPressed(event: var)

    function focusInput(): void {
        editor.forceActiveFocus();
    }
    function clear(): void {
        editor.text = "";
    }

    implicitHeight: 48
    radius: Theme.radiusSm
    color: Theme.background
    border.width: editor.activeFocus ? 2 : 1
    border.color: editor.activeFocus ? Theme.accent : Theme.outline

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceMd
        anchors.rightMargin: Theme.spaceMd
        spacing: Theme.spaceMd

        NixiIcon {
            visible: root.leadingIcon !== ""
            name: root.leadingIcon
            size: Theme.iconMedium
            color: Theme.foregroundMuted
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: editor
                anchors.fill: parent
                color: Theme.foreground
                font.pixelSize: Theme.fontBody
                verticalAlignment: TextInput.AlignVCenter
                enabled: root.inputEnabled && !root.busy
                echoMode: root.password ? TextInput.Password : TextInput.Normal
                passwordCharacter: "●"
                selectByMouse: root.selectByMouse
                inputMethodHints: root.password ? Qt.ImhHiddenText | Qt.ImhSensitiveData : Qt.ImhNone
                onTextEdited: root.edited(text)
                Keys.onPressed: event => root.keyPressed(event)
                Keys.onReturnPressed: root.accepted()
                Keys.onEnterPressed: root.accepted()
                Keys.onEscapePressed: root.escapePressed()

                HoverHandler {
                    enabled: editor.enabled
                    cursorShape: Qt.IBeamCursor
                }
            }

            Text {
                anchors.fill: parent
                visible: editor.text.length === 0 && !editor.activeFocus && !root.busy
                text: root.placeholder
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontBody
                verticalAlignment: Text.AlignVCenter
            }
        }

        Text {
            visible: root.busy
            text: root.busyText
            color: Theme.accent
            font.pixelSize: Theme.fontSmall
            font.weight: Theme.fontWeightMedium
        }
    }
}
