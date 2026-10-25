pragma Singleton
import QtQuick
import Quickshell.Services.Polkit
import ".."

// Owns the desktop session's PolicyKit agent. The UI only ever sees the
// current conversation and submits a response directly to AuthFlow; secrets
// are deliberately not retained here or exposed through IPC.
QtObject {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive
    readonly property bool registered: agent.isRegistered

    function submit(response: string): void {
        if (flow !== null && flow.isResponseRequired)
            flow.submit(response);
    }

    function cancel(): void {
        if (flow !== null)
            flow.cancelAuthenticationRequest();
    }

    property PolkitAgent agent: PolkitAgent {
        id: agent
    }
}
