pragma Singleton
import QtQuick
import Quickshell.Io
import ".."

// bluetoothctl supplies BlueZ's KeyboardDisplay agent API, including PIN,
// passkey confirmation, and service authorization challenges.
QtObject {
    id: root

    property bool started: false
    property bool agentReady: false
    property var device: null
    property bool active: device !== null
    property bool waiting: false
    property string promptType: ""
    property string promptText: ""
    property string displayedCode: ""
    property string error: ""

    function start(): void {
        if (started)
            return;
        started = true;
        agent.running = true;
    }

    function pair(target: var): void {
        if (!target)
            return;
        start();
        device = target;
        error = "";
        clearPrompt();
        if (BluetoothService.adapter !== null) {
            BluetoothService.adapter.pairable = true;
            BluetoothService.adapter.discovering = true;
        }
        if (agentReady)
            beginPairing();
        else
            agent.running = true;
    }

    function beginPairing(): void {
        if (!device)
            return;
        waiting = true;
        agent.write("pair " + device.address + "\n");
    }

    function clearPrompt(): void {
        promptType = "";
        promptText = "";
        displayedCode = "";
    }

    function answer(value: string): void {
        if (!active)
            return;
        agent.write(value + "\n");
        clearPrompt();
        waiting = true;
    }

    function accept(): void {
        answer("yes");
    }
    function reject(): void {
        answer("no");
    }
    function submit(code: string): void {
        if (code !== "")
            answer(code);
    }

    function cancel(): void {
        if (device)
            agent.write("cancel-pairing " + device.address + "\n");
        clearPrompt();
        waiting = false;
        device = null;
    }

    function clean(line: string): string {
        return line.replace(/\x1b\[[0-9;?]*[ -\/]*[@-~]/g, "").trim();
    }

    function handleLine(rawLine: string): void {
        const line = clean(rawLine);
        if (line === "")
            return;
        let match = line.match(/Confirm passkey\s+([0-9]+)/i);
        if (match) {
            waiting = false;
            promptType = "confirm";
            displayedCode = match[1];
            promptText = "Confirm that this code matches the other device";
            return;
        }
        match = line.match(/PIN code:\s*([0-9]+)/i);
        if (match) {
            waiting = false;
            promptType = "display";
            displayedCode = match[1];
            promptText = "Enter this PIN on the other device";
            return;
        }
        if (/Enter PIN code/i.test(line)) {
            waiting = false;
            promptType = "pin";
            promptText = "Enter the device PIN";
            return;
        }
        if (/Enter passkey/i.test(line)) {
            waiting = false;
            promptType = "passkey";
            promptText = "Enter the device passkey";
            return;
        }
        if (/Authorize service/i.test(line)) {
            waiting = false;
            promptType = "authorize";
            promptText = "Allow this device to use the requested service?";
            return;
        }
        if (/Pairing successful|Paired:\s*yes/i.test(line)) {
            const completed = device;
            clearPrompt();
            waiting = false;
            if (completed) {
                agent.write("trust " + completed.address + "\n");
                agent.write("connect " + completed.address + "\n");
            }
            device = null;
            return;
        }
        if (/Failed to pair|AuthenticationFailed|AuthenticationCanceled|not available/i.test(line)) {
            error = line.replace(/^.*Failed to pair:\s*/i, "");
            clearPrompt();
            waiting = false;
        }
    }

    property Process agent: Process {
        command: ["bluetoothctl", "--agent", "KeyboardDisplay"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => root.handleLine(data)
        }
        stderr: SplitParser {
            onRead: data => root.handleLine(data)
        }
        onStarted: {
            root.agentReady = true;
            write("agent KeyboardDisplay\n");
            write("default-agent\n");
            if (root.device)
                root.beginPairing();
        }
        onRunningChanged: {
            if (!running) {
                root.agentReady = false;
            }
            if (!running && root.started)
                restartDelay.restart();
        }
    }
    property Timer restartDelay: Timer {
        interval: 1000
        onTriggered: agent.running = true
    }
}
