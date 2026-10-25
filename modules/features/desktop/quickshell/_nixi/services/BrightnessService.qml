pragma Singleton
import QtQuick
import Quickshell.Io
import ".."

QtObject {
    id: root
    property bool feedbackEnabled: false
    property string devicePath: ""
    property real maximum: 1
    property real level: 0
    property bool initialized: false

    function start(): void { feedbackDelay.restart(); }

    property Timer feedbackDelay: Timer {
        interval: 1000
        onTriggered: root.feedbackEnabled = true
    }
    property Process discovery: Process {
        running: true
        command: ["bash", "-c", "find /sys/class/backlight -mindepth 1 -maxdepth 1 -type l -print -quit 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.devicePath = text.trim() }
    }
    property FileView maximumFile: FileView {
        path: root.devicePath === "" ? "" : root.devicePath + "/max_brightness"
        onTextChanged: root.maximum = Math.max(1, Number(text().trim()) || 1)
    }
    property FileView levelFile: FileView {
        path: root.devicePath === "" ? "" : root.devicePath + "/brightness"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            const next = Math.max(0, Math.min(1, (Number(text().trim()) || 0) / root.maximum));
            root.level = next;
            if (root.initialized && root.feedbackEnabled)
                PopupController.showOsd("display-brightness-symbolic", "Brightness", next, "level");
            root.initialized = true;
        }
    }
}
