pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam
import ".."

// Owns the lock state and its PAM conversation. Passwords pass straight to
// PAM and are never retained by this singleton.
QtObject {
    id: root

    property bool locked: false
    readonly property string username: Quickshell.env("USER") || "user"
    property bool authenticating: false
    readonly property bool awaitingResponse: pam.responseRequired && !authenticating
    readonly property bool busy: authenticating || retryDelay.running || (pam.active && !pam.responseRequired)
    property string statusMessage: ""
    property bool failed: false

    function lock(): void {
        if (locked)
            return;
        failed = false;
        authenticating = false;
        statusMessage = "";
        locked = true;
        startDelay.restart();
    }

    function beginAuthentication(): void {
        if (!locked || pam.active)
            return;
        pam.start();
    }

    function submit(password: string): void {
        if (locked && pam.responseRequired && !authenticating) {
            authenticating = true;
            failed = false;
            statusMessage = "";
            pam.respond(password);
        }
    }

    property Timer startDelay: Timer {
        interval: 100
        onTriggered: root.beginAuthentication()
    }

    property PamContext pam: PamContext {
        id: pam
        config: "login"
        user: root.username

        onPamMessage: {
            if (!responseRequired && message.length > 0)
                root.statusMessage = message;
        }
        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.statusMessage = "";
                root.failed = false;
                root.locked = false;
            } else if (root.locked) {
                root.failed = true;
                root.statusMessage = result === PamResult.MaxTries ? "Too many attempts. Please wait and try again." : "That password was not accepted.";
                retryDelay.restart();
            }
        }
        onError: error => {
            root.failed = true;
            root.statusMessage = "Authentication is temporarily unavailable.";
        }
    }

    property Timer retryDelay: Timer {
        interval: 180
        onTriggered: root.beginAuthentication()
    }
}
