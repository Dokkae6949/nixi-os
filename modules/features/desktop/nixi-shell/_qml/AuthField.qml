import QtQuick

// A single-line input for the lock screen and greeter: icon, placeholder,
// accent border while typing, red border and a shake on failure.
Rectangle {
    id: root

    property string icon: "\u{F033E}"
    property string placeholder
    property bool secret: true
    property bool busy: false
    property bool failed: false
    property alias text: input.text
    signal submitted(string text)

    function shake(): void {
        shakeAnimation.restart();
    }
    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitWidth: 380
    implicitHeight: 48
    color: Theme.bg1
    border.width: Theme.borderWidth
    border.color: failed ? Theme.red : input.activeFocus && input.text !== "" ? Theme.accent : Theme.bg2

    transform: Translate {
        id: offset
    }

    SequentialAnimation {
        id: shakeAnimation
        loops: 2
        NumberAnimation { target: offset; property: "x"; to: 10; duration: 40 }
        NumberAnimation { target: offset; property: "x"; to: -10; duration: 80 }
        NumberAnimation { target: offset; property: "x"; to: 0; duration: 40 }
    }

    Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.busy ? "\u{F0996}" : root.icon
        color: root.failed ? Theme.red : Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.iconSize + 2
    }

    TextInput {
        id: input
        anchors.left: glyph.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        focus: true
        enabled: !root.busy
        echoMode: root.secret ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        color: Theme.fg
        selectionColor: Theme.bg2
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 4
        font.letterSpacing: root.secret ? 2 : 0
        onAccepted: {
            if (text !== "")
                root.submitted(text);
        }
        onEnabledChanged: if (enabled) forceActiveFocus()
        Keys.onEscapePressed: text = ""

        Text {
            visible: input.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.busy ? "Checking…" : root.placeholder
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
        }
    }
}
