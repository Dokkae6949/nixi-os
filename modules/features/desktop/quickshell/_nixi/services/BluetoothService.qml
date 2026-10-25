pragma Singleton
import QtQuick
import Quickshell.Bluetooth
import ".."

QtObject {
    function hasFriendlyName(device: var): bool {
        const candidate = String(device.name || device.deviceName || "");
        return candidate !== "" && candidate.toUpperCase() !== String(device.address).toUpperCase();
    }
    function deviceIcon(device: var): string {
        const icon = String(device.icon || "").toLowerCase();
        if (icon.includes("head") || icon.includes("audio") || icon.includes("speaker"))
            return "audio-headphones-symbolic";
        if (icon.includes("phone"))
            return "phone-symbolic";
        if (icon.includes("keyboard"))
            return "input-keyboard-symbolic";
        if (icon.includes("mouse") || icon.includes("input-gaming"))
            return "input-mouse-symbolic";
        if (icon.includes("computer"))
            return "computer-symbolic";
        return "bluetooth-symbolic";
    }
    function displayName(device: var): string {
        if (hasFriendlyName(device))
            return String(device.name || device.deviceName);
        const icon = String(device.icon || "").toLowerCase();
        if (icon.includes("head") || icon.includes("audio"))
            return "Unnamed audio device";
        if (icon.includes("phone"))
            return "Unnamed phone";
        if (icon.includes("keyboard"))
            return "Unnamed keyboard";
        if (icon.includes("mouse"))
            return "Unnamed mouse";
        return "Unnamed Bluetooth device";
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter !== null && (adapter.state === BluetoothAdapterState.Enabled || adapter.state === BluetoothAdapterState.Enabling)
    readonly property var devices: Bluetooth.devices.values.slice().sort((a, b) => {
        if (a.connected !== b.connected)
            return b.connected - a.connected;
        if (a.paired !== b.paired)
            return b.paired - a.paired;
        return displayName(a).localeCompare(displayName(b));
    })

    function toggle(): void {
        if (adapter !== null)
            adapter.enabled = !adapter.enabled;
    }
    function setDiscovering(discovering: bool): void {
        if (adapter !== null && adapter.enabled) {
            adapter.pairable = discovering;
            adapter.discovering = discovering;
        }
    }
    function activate(device: var): void {
        if (!device)
            return;
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            BluetoothPairingService.pair(device);
    }
}
