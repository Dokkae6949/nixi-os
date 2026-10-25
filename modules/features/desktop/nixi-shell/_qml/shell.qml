import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Bar {}
    Popups {}
    Osd {}
    LockScreen {}
    Polkit {}
    Idle {}

    LazyLoader {
        active: Ui.panel === "apps" || Ui.panel === "clipboard"
        Launcher {}
    }

    // qs -c nixi-shell ipc call nixi-shell <function> [args]
    IpcHandler {
        target: "nixi-shell"

        function launcher(): void {
            Ui.toggle("apps");
        }
        function clipboard(): void {
            Ui.toggle("clipboard");
        }
        function notifications(): void {
            Ui.toggle("notifications");
        }
        // Panel open: dismiss the selected entry. Otherwise hide the newest
        // popup, which stays in history.
        function dismiss(): void {
            if (Ui.panel === "notifications")
                Notifs.dismissSelected();
            else
                Notifs.hideNewestPopup();
        }
        function close(): void {
            Ui.close();
        }
        function dnd(): void {
            Notifs.toggleDnd();
        }
        function battery(): void {
            Battery.report();
        }
        function cyclePowerProfile(): void {
            Sys.cycleProfile();
        }
        function lock(): void {
            Session.lock();
        }

        function brightnessUp(percent: int): void {
            Sys.stepBrightness(percent);
        }
        function brightnessDown(percent: int): void {
            Sys.stepBrightness(-percent);
        }
        function volumeUp(percent: int): void {
            Audio.stepVolume(percent);
        }
        function volumeDown(percent: int): void {
            Audio.stepVolume(-percent);
        }
        function volumeMute(): void {
            Audio.toggleMute();
        }
        function micMute(): void {
            Audio.toggleMic();
        }
        function wifi(): void {
            Radio.toggleWifi();
        }
        function bluetooth(): void {
            Radio.toggleBluetooth();
        }
    }
}
