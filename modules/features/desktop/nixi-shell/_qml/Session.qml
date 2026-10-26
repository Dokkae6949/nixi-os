pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Lock state, its PAM conversation, and session commands.
Singleton {
    id: root

    property bool locked: false
    property string message: ""
    property bool failed: false
    // Set by LockScreen once the compositor confirms every output is covered.
    property bool secure: false
    // Bumped on every rejected password, so the lock screen can react.
    property int failures: 0
    // True from submitting a password until PAM answers, so input stays locked meanwhile.
    property bool checking: false
    readonly property string user: Quickshell.env("USER") || "user"

    function lock(): void {
        if (locked)
            return;
        Ui.panel = "";
        Notifs.clearPopups();
        message = "";
        failed = false;
        checking = false;
        locked = true;
        pam.start();
    }

    function submit(password: string): void {
        if (pam.responseRequired) {
            message = "";
            checking = true;
            pam.respond(password);
        }
    }

    function run(command: list<string>): void {
        Quickshell.execDetached(command);
    }

    PamContext {
        id: pam
        config: "login"
        user: root.user

        onPamMessage: {
            if (!responseRequired && message.length > 0)
                root.message = message;
        }
        onResponseRequiredChanged: if (responseRequired) root.checking = false
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                root.locked = false;
                root.failed = false;
                root.message = "";
            } else {
                root.failed = true;
                root.failures++;
                root.message = result === PamResult.MaxTries ? "Too many attempts" : "Wrong password";
                restart.start();
            }
        }
        onError: {
            root.checking = false;
            root.failed = true;
            root.message = "PAM error";
            restart.start();
        }
    }

    Timer {
        id: restart
        interval: 200
        onTriggered: if (root.locked && !pam.active) pam.start()
    }
}
