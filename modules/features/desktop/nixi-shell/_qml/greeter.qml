import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland

// The greetd login screen. Runs as the `greeter` user inside a bare Niri (see
// ../greeter.nix), looks like the lock screen, and remembers the last user and
// session. Launching a session quits Quickshell, which ends that Niri.
//
//   NIXI_GREETER_SESSIONS  JSON list of { name, command: "shell line", env: [..] }
//   NIXI_GREETER_STATE     writable JSON file for the last user and session
ShellRoot {
    id: root

    property var sessions: []
    property int sessionIndex: 0
    readonly property var session: sessions[sessionIndex] ?? null

    property string user: ""
    property string message: ""
    property bool failed: false
    property int failures: 0
    property bool echo: false
    property bool busy: false
    property bool choosing: false

    signal shake

    FileView {
        id: sessionsFile
        path: Quickshell.env("NIXI_GREETER_SESSIONS") ?? ""
        blockLoading: true
    }

    FileView {
        id: stateFile
        path: Quickshell.env("NIXI_GREETER_STATE") ?? ""
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: {
        try {
            sessions = JSON.parse(sessionsFile.text());
        } catch (e) {
            sessions = [{ name: "Niri", command: "niri-session", env: [] }];
        }
        let saved = {};
        try {
            saved = JSON.parse(stateFile.text() || "{}");
        } catch (e) {}
        const i = sessions.findIndex(s => s.name === saved.session);
        sessionIndex = i >= 0 ? i : 0;
        if (saved.user)
            begin(saved.user);
    }

    function begin(name: string): void {
        user = name.trim();
        message = "";
        if (user === "")
            return;
        busy = true;
        Greetd.createSession(user);
    }

    function changeUser(): void {
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        user = "";
        busy = false;
        failed = false;
        message = "";
    }

    function respond(text: string): void {
        busy = true;
        failed = false;
        Greetd.respond(text);
    }

    function launch(): void {
        stateFile.setText(JSON.stringify({ user: user, session: session.name }));
        // greetd joins the argv and runs it through `sh -c` anyway.
        Greetd.launch([session.command], session.env);
    }

    function power(action: string): void {
        Quickshell.execDetached(["systemctl", action]);
    }

    Connections {
        target: Greetd

        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            if (responseRequired) {
                root.busy = false;
                root.echo = echoResponse;
                // PAM's prompts ("Password: ") are noise next to the placeholder.
                if (!/^password:?\s*$/i.test(message))
                    root.message = message;
            } else {
                root.message = message;
                root.failed = error;
            }
        }

        function onAuthFailure(message: string): void {
            root.failed = true;
            root.message = "Wrong password";
            root.shake();
            retry.start();
        }

        function onReadyToLaunch(): void {
            root.launch();
        }

        // Unknown users and the like: start over from the username.
        function onError(error: string): void {
            root.changeUser();
            root.failed = true;
            root.message = error;
        }
    }

    Timer {
        id: retry
        interval: 300
        onTriggered: root.begin(root.user)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property var modelData
            readonly property bool primary: modelData === Quickshell.screens[0]

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.bgHard
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nixi-greeter"
            WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            component Button: Rectangle {
                id: button
                property string icon
                property string label
                property color tint: Theme.fg
                signal clicked

                implicitWidth: row.implicitWidth + 24
                implicitHeight: Theme.barHeight + 4
                color: hover.hovered ? Theme.bg2 : Theme.bg1

                HoverHandler {
                    id: hover
                }
                TapHandler {
                    onTapped: button.clicked()
                }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: button.icon
                        color: button.tint
                        font.family: Theme.font
                        font.pixelSize: Theme.iconSize
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: button.label !== ""
                        text: button.label
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            LockFrame {
                anchors.fill: parent
                primary: window.primary

                Column {
                    spacing: 12

                    AuthField {
                        id: field
                        icon: root.user === "" ? "\u{F0004}" : "\u{F033E}"
                        placeholder: root.user === "" ? "Username" : "Password for " + root.user
                        secret: root.user !== "" && !root.echo
                        busy: root.busy
                        failed: root.failed
                        onSubmitted: text => {
                            field.text = "";
                            if (root.user === "")
                                root.begin(text);
                            else
                                root.respond(text);
                        }
                        onTextChanged: if (text !== "") root.failed = false

                        Connections {
                            target: root
                            function onShake(): void {
                                field.shake();
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: text !== ""
                        text: root.message
                        color: root.failed ? Theme.red : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }

                    // Session picker and user switch.
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.gap

                        Button {
                            icon: "\u{F0379}"
                            label: (root.session?.name ?? "Session") + "  \u{F0140}"
                            tint: Theme.aqua
                            onClicked: root.choosing = !root.choosing
                        }
                        Button {
                            visible: root.user !== ""
                            icon: "\u{F0004}"
                            label: "Other user"
                            tint: Theme.blue
                            onClicked: {
                                root.changeUser();
                                field.focusInput();
                            }
                        }
                    }

                    Rectangle {
                        visible: root.choosing
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: field.width
                        height: list.implicitHeight + 2 * Theme.borderWidth
                        color: Theme.bg
                        border.width: Theme.borderWidth
                        border.color: Theme.border

                        Column {
                            id: list
                            anchors.fill: parent
                            anchors.margins: Theme.borderWidth

                            Repeater {
                                model: root.sessions

                                Rectangle {
                                    required property var modelData
                                    required property int index
                                    width: list.width
                                    height: 34
                                    color: rowHover.hovered ? Theme.bg2 : index === root.sessionIndex ? Theme.bg1 : "transparent"

                                    HoverHandler {
                                        id: rowHover
                                    }
                                    TapHandler {
                                        onTapped: {
                                            root.sessionIndex = index;
                                            root.choosing = false;
                                            field.focusInput();
                                        }
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14
                                        spacing: 10

                                        Text {
                                            width: Theme.iconSize
                                            text: index === root.sessionIndex ? "\u{F012C}" : ""
                                            color: Theme.accent
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize
                                        }
                                        Text {
                                            text: modelData.name
                                            color: index === root.sessionIndex ? Theme.accent : Theme.fg
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                corner: [
                    Button {
                        icon: "\u{F04B2}"
                        tint: Theme.blue
                        onClicked: root.power("suspend")
                    },
                    Button {
                        icon: "\u{F0709}"
                        tint: Theme.yellow
                        onClicked: root.power("reboot")
                    },
                    Button {
                        icon: "\u{F0425}"
                        tint: Theme.red
                        onClicked: root.power("poweroff")
                    }
                ]
            }
        }
    }
}
