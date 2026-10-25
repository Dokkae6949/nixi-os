pragma Singleton
import QtQuick
import Quickshell

// Which panel is open: "", "apps", "clipboard" or "notifications".
// Only one panel exists at a time; everything else is the bar.
Singleton {
    property string panel: ""

    function toggle(name: string): void {
        panel = panel === name ? "" : name;
    }

    function close(): void {
        if (panel !== "")
            panel = "";
        else
            Notifs.clearPopups();
    }
}
