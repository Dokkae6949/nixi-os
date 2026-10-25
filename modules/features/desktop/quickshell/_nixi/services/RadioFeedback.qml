pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Networking
import ".."

QtObject {
    id: root
    property bool enabled: false
    property string bluetoothSwitchPath: ""
    property bool bluetoothInitialized: false
    property bool bluetoothEnabled: false
    property bool predictionPending: false
    readonly property bool wifiEnabled: Networking.wifiEnabled && Networking.wifiHardwareEnabled

    function start(): void { delay.restart(); }
    function reportBluetoothKey(): void {
        bluetoothEnabled = predictionPending ? !bluetoothEnabled : !BluetoothService.enabled;
        bluetoothInitialized = true;
        predictionPending = true;
        predictionTimeout.restart();
        PopupController.showOsd("bluetooth-symbolic", "Bluetooth", bluetoothEnabled ? 1 : 0, "status");
    }
    function updateBluetooth(blocked: string): void {
        const next = blocked.trim() === "0";
        if (predictionPending) {
            if (next === bluetoothEnabled) {
                predictionPending = false;
                predictionTimeout.stop();
            }
            return;
        }
        if (bluetoothInitialized && next !== bluetoothEnabled && enabled)
            PopupController.showOsd("bluetooth-symbolic", "Bluetooth", next ? 1 : 0, "status");
        bluetoothEnabled = next;
        bluetoothInitialized = true;
    }

    property Timer delay: Timer { interval: 1000; onTriggered: root.enabled = true }
    property Timer predictionTimeout: Timer {
        interval: 12000
        onTriggered: { root.predictionPending = false; softBlock.reload(); }
    }
    property Process discovery: Process {
        running: true
        command: ["bash", "-c", "for device in /sys/class/rfkill/rfkill*; do [ \"$(cat \"$device/name\" 2>/dev/null)\" = tpacpi_bluetooth_sw ] && printf '%s' \"$device\" && break; done"]
        stdout: StdioCollector { onStreamFinished: root.bluetoothSwitchPath = text.trim() }
    }
    property FileView softBlock: FileView {
        path: root.bluetoothSwitchPath === "" ? "" : root.bluetoothSwitchPath + "/soft"
        onTextChanged: root.updateBluetooth(text())
    }
    property Process events: Process {
        running: root.bluetoothSwitchPath !== ""
        command: ["rfkill", "event"]
        stdout: SplitParser { onRead: root.softBlock.reload() }
    }
    property Connections networkSignals: Connections {
        target: Networking
        function onWifiEnabledChanged(): void {
            if (root.enabled)
                PopupController.showOsd("network-wireless-symbolic", "Wi-Fi", root.wifiEnabled ? 1 : 0, "status");
        }
        function onWifiHardwareEnabledChanged(): void {
            if (root.enabled)
                PopupController.showOsd("network-wireless-symbolic", "Wi-Fi", root.wifiEnabled ? 1 : 0, "status");
        }
    }
}
