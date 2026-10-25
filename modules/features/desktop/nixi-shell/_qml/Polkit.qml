import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland

// PolicyKit agent; the prompt surface only exists during a request.
Scope {
    id: root

    PolkitAgent {
        id: agent
    }

    LazyLoader {
        active: agent.isActive

        PanelWindow {
            readonly property AuthFlow flow: agent.flow

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "#99000000"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "nixi-shell-polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.centerIn: parent
                width: 460
                height: column.implicitHeight + 40
                color: Theme.bg
                border.width: Theme.borderWidth
                border.color: Theme.accent

                Column {
                    id: column
                    x: 20
                    y: 20
                    width: parent.width - 40
                    spacing: 12

                    Text {
                        width: parent.width
                        text: "Authentication required"
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 2
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: flow?.message ?? ""
                        color: Theme.fg
                        wrapMode: Text.Wrap
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: Theme.bg
                        border.width: Theme.borderWidth
                        border.color: input.activeFocus ? Theme.accent : Theme.border

                        TextInput {
                            id: input
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            focus: true
                            enabled: flow?.isResponseRequired ?? false
                            echoMode: flow?.responseVisible ? TextInput.Normal : TextInput.Password
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            onEnabledChanged: if (enabled) forceActiveFocus()
                            onAccepted: {
                                flow.submit(text);
                                text = "";
                            }
                            Keys.onEscapePressed: flow?.cancelAuthenticationRequest()

                            Text {
                                visible: input.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: (flow?.inputPrompt || "Password").replace(/:\s*$/, "")
                                color: Theme.muted
                                font: input.font
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: flow?.failed ? "Authentication failed, try again" : flow?.supplementaryMessage ?? ""
                        color: flow?.failed || flow?.supplementaryIsError ? Theme.red : Theme.muted
                        wrapMode: Text.Wrap
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Text {
                        text: "Enter to confirm · Esc to cancel"
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
    }
}
