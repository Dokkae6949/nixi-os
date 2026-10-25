pragma Singleton
import QtQuick
import Quickshell.Io
import ".."

QtObject {
    id: root
    function run(command: list<string>): void {
        process.command = command;
        process.running = true;
    }
    function lock(): void { run(["loginctl", "lock-session"]); }
    function suspend(): void { run(["systemctl", "suspend"]); }
    function logout(): void { run(["niri", "msg", "action", "quit", "--skip-confirmation"]); }
    function reboot(): void { run(["systemctl", "reboot"]); }
    function powerOff(): void { run(["systemctl", "poweroff"]); }
    property Process process: Process {}
}
