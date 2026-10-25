pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

// Wi-Fi/Ethernet (NetworkManager) and Bluetooth (BlueZ) through the native
// services. Both fill in asynchronously after startup.
Singleton {
    id: root

    readonly property bool wifiEnabled: Networking.wifiEnabled
    // { wired: bool, name: string, strength: 0-100 } or null when offline.
    readonly property var link: {
        for (const d of Networking.devices.values) {
            if (!d.connected)
                continue;
            if (d.type === DeviceType.Wired)
                return { wired: true, name: "Ethernet", strength: 100 };
            if (d.type === DeviceType.Wifi) {
                for (const n of d.networks.values) {
                    if (n.connected)
                        return { wired: false, name: n.name, strength: Math.round(n.signalStrength <= 1 ? n.signalStrength * 100 : n.signalStrength) };
                }
            }
        }
        return null;
    }
    readonly property string linkName: link?.name ?? ""

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: adapter?.enabled ?? false
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string btNames: btConnected.map(d => d.name).join(", ")

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleBluetooth(): void {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
}
