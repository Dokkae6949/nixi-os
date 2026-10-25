import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

PanelWindow {
    id: root

    readonly property var flow: AuthenticationService.flow
    readonly property bool awaitingResponse: flow !== null && flow.isResponseRequired
    readonly property bool promptActive: AuthenticationService.active
    property string requestMessage: ""
    property string requestActionId: ""
    property string requestIconName: ""

    visible: promptActive || scrim.opacity > 0 || card.opacity > 0
    color: "transparent"
    exclusiveZone: 0
    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nixi-authentication"
    WlrLayershell.keyboardFocus: promptActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function focusInput(): void {
        responseField.clear();
        if (promptActive && awaitingResponse)
            responseField.focusInput();
    }

    function submit(): void {
        if (!awaitingResponse)
            return;
        const value = responseField.text;
        responseField.clear();
        AuthenticationService.submit(value);
    }

    function retainRequestDetails(): void {
        if (flow === null)
            return;
        requestMessage = flow.message;
        requestActionId = flow.actionId;
        requestIconName = flow.iconName;
    }

    onFlowChanged: retainRequestDetails()
    onPromptActiveChanged: if (promptActive)
        Qt.callLater(retainRequestDetails)

    onVisibleChanged: {
        if (promptActive)
            Qt.callLater(focusInput);
        else
            responseField.clear();
    }
    onAwaitingResponseChanged: if (awaitingResponse)
        Qt.callLater(focusInput)

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: AuthenticationService.cancel()
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#99000000"
        opacity: root.promptActive ? 1 : 0
        enabled: root.promptActive
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.fast
                easing.type: Motion.easing
            }
        }
        TapHandler {
            enabled: root.promptActive
            onTapped: AuthenticationService.cancel()
        }
    }

    BaseSurface {
        id: card
        anchors.centerIn: parent
        width: Math.min(460, root.width - Theme.spaceXl * 2)
        height: content.implicitHeight + Theme.spaceXl * 2
        radius: Theme.radiusPanel
        opacity: root.promptActive ? 1 : 0
        scale: root.promptActive ? 1 : 0.96
        enabled: root.promptActive

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.fast
                easing.type: Motion.easing
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.normal
                easing.type: Motion.easing
            }
        }

        TapHandler {
            onTapped: function () {}
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Theme.spaceXl
            spacing: Theme.spaceLg

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceMd

                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: 22
                    color: Theme.accent
                    NixiIcon {
                        anchors.centerIn: parent
                        name: root.requestIconName.length > 0 && Quickshell.iconPath(root.requestIconName, true) !== "" ? root.requestIconName : "nixi-authentication-symbolic"
                        color: Theme.accentForeground
                        size: Theme.iconLarge
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceXs
                    Text {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        color: Theme.foreground
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.requestActionId
                        color: Theme.foregroundMuted
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideMiddle
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.requestMessage.length > 0 ? root.requestMessage : "An application is requesting permission to perform a privileged action."
                color: Theme.foreground
                font.pixelSize: Theme.fontBody
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                readonly property bool authenticationFailed: root.flow !== null && root.flow.failed
                readonly property string pamMessage: root.flow !== null ? root.flow.supplementaryMessage : ""
                visible: pamMessage.length > 0 || authenticationFailed
                text: authenticationFailed ? "Authentication failed. Check your password and try again." : pamMessage
                color: authenticationFailed || (root.flow !== null && root.flow.supplementaryIsError) ? Theme.critical : Theme.foregroundMuted
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.Wrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceSm

                Text {
                    Layout.fillWidth: true
                    text: root.flow !== null && root.flow.inputPrompt.length > 0 ? root.flow.inputPrompt : "Password"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontSmall
                }

                TextEntry {
                    id: responseField
                    Layout.fillWidth: true
                    implicitHeight: 46
                    inputEnabled: root.awaitingResponse
                    password: root.flow === null || !root.flow.responseVisible
                    onAccepted: root.submit()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceMd
                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 92
                    implicitHeight: Theme.controlSize
                    radius: Theme.radiusSm
                    color: cancelHover.hovered ? Theme.surfaceRaised : "transparent"
                    border.width: 1
                    border.color: Theme.outline
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.foreground
                    }
                    HoverHandler {
                        id: cancelHover
                    }
                    TapHandler {
                        onTapped: AuthenticationService.cancel()
                    }
                }

                Rectangle {
                    implicitWidth: 112
                    implicitHeight: Theme.controlSize
                    radius: Theme.radiusSm
                    color: root.awaitingResponse ? Theme.accent : Theme.surfaceRaised
                    opacity: root.awaitingResponse ? 1 : 0.65
                    Text {
                        anchors.centerIn: parent
                        text: root.awaitingResponse ? "Authenticate" : "Waiting…"
                        color: root.awaitingResponse ? Theme.accentForeground : Theme.foregroundMuted
                        font.weight: Font.DemiBold
                    }
                    TapHandler {
                        enabled: root.awaitingResponse
                        onTapped: root.submit()
                    }
                }
            }
        }
    }
}
