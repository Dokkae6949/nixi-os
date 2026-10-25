pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import ".."

QtObject {
    id: root

    readonly property var wifiDevices: Networking.devices.values.filter(device => device.type === DeviceType.Wifi)
    readonly property var primaryWifiDevice: wifiDevices.length > 0 ? wifiDevices[0] : null
    readonly property var wifiDevice: {
        for (const device of wifiDevices) {
            if (device.connected)
                return device;
        }
        return primaryWifiDevice;
    }
    readonly property var wifiNetworks: {
        const result = [];
        const seen = {};
        for (const device of wifiDevices) {
            for (const network of device.networks.values) {
                const key = network.name + "\u0000" + network.security;
                if (!seen[key]) {
                    seen[key] = true;
                    result.push(network);
                }
            }
        }
        return result.sort((a, b) => {
            if (a.connected !== b.connected)
                return b.connected - a.connected;
            if (a.known !== b.known)
                return b.known - a.known;
            return normalizedStrength(b.signalStrength) - normalizedStrength(a.signalStrength);
        });
    }
    readonly property var wifiNetwork: {
        for (const network of wifiNetworks) {
            if (network.connected)
                return network;
        }
        return null;
    }
    readonly property bool wifiConnected: Networking.wifiEnabled && wifiNetwork !== null
    readonly property int wifiStrength: wifiNetwork === null ? 0 : normalizedStrength(wifiNetwork.signalStrength)
    readonly property bool wiredConnected: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wired && device.connected)
                return true;
        }
        return false;
    }
    property bool enterpriseBusy: false
    property string enterpriseError: ""
    property string enterpriseStage: ""
    property string pendingSecret: ""
    property bool secretReady: false
    property string enterpriseProfile: ""
    property var enterpriseNetwork: null
    property string enterpriseIdentity: ""
    property string enterpriseAnonymousIdentity: ""
    property string enterpriseMethod: "peap"
    property string enterprisePhase2: "mschapv2"
    property string enterpriseCaCertificate: ""
    property string enterpriseClientCertificate: ""
    property string enterprisePrivateKey: ""
    property string enterpriseDomain: ""
    property string enterpriseSecretKey: "802-1x.password"
    readonly property string secretPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/nixi-wifi-secret-" + Quickshell.processId

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function normalizedStrength(value: real): int {
        return Math.max(0, Math.min(100, Math.round(value <= 1 ? value * 100 : value)));
    }

    function setScanning(enabled: bool): void {
        for (const device of wifiDevices)
            device.scannerEnabled = enabled;
    }

    function securityLabel(network: var): string {
        if (!network)
            return "Unknown";
        switch (network.security) {
        case WifiSecurityType.Open:
            return "Open";
        case WifiSecurityType.Owe:
            return "Enhanced open";
        case WifiSecurityType.Sae:
            return "WPA3";
        case WifiSecurityType.Wpa2Psk:
            return "WPA2";
        case WifiSecurityType.WpaPsk:
            return "WPA";
        case WifiSecurityType.Wpa2Eap:
            return "WPA2 Enterprise";
        case WifiSecurityType.WpaEap:
            return "WPA Enterprise";
        case WifiSecurityType.Wpa3SuiteB192:
            return "WPA3 Enterprise";
        case WifiSecurityType.StaticWep:
            return "WEP";
        case WifiSecurityType.DynamicWep:
            return "Dynamic WEP";
        case WifiSecurityType.Leap:
            return "LEAP";
        default:
            return "Secured";
        }
    }

    function isEnterprise(network: var): bool {
        return network && (network.security === WifiSecurityType.Wpa2Eap || network.security === WifiSecurityType.WpaEap || network.security === WifiSecurityType.Wpa3SuiteB192 || network.security === WifiSecurityType.DynamicWep || network.security === WifiSecurityType.Leap);
    }

    function requiresPassword(network: var): bool {
        return network && network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe && !isEnterprise(network);
    }

    function connectNetwork(network: var, password: string): void {
        if (!network || network.stateChanging)
            return;
        enterpriseError = "";
        if (network.connected) {
            network.disconnect();
        } else if (network.known || !requiresPassword(network)) {
            network.connect();
        } else {
            network.connectWithPsk(password);
        }
    }

    function connectEnterprise(network: var, identity: string, password: string, method: string, phase2: string, anonymousIdentity: string, caCertificate: string, clientCertificate: string, privateKey: string, domain: string): void {
        const tlsReady = method === "tls" && clientCertificate.trim() !== "" && privateKey.trim() !== "";
        if (!network || enterpriseBusy || identity.trim() === "" || (method !== "tls" && password === "") || (method === "tls" && !tlsReady))
            return;
        enterpriseBusy = true;
        enterpriseError = "";
        enterpriseNetwork = network;
        enterpriseIdentity = identity.trim();
        enterpriseAnonymousIdentity = anonymousIdentity.trim();
        enterpriseMethod = method;
        enterprisePhase2 = phase2;
        enterpriseCaCertificate = caCertificate.trim();
        enterpriseClientCertificate = clientCertificate.trim();
        enterprisePrivateKey = privateKey.trim();
        enterpriseDomain = domain.trim();
        enterpriseSecretKey = method === "tls" ? "802-1x.private-key-password" : "802-1x.password";
        enterpriseProfile = "Nixi " + network.name + " " + Date.now();
        pendingSecret = password;
        enterpriseStage = "preparing-secret";
        prepareSecret.exec(["install", "-m", "600", "/dev/null", secretPath]);
    }

    function failEnterprise(message: string): void {
        enterpriseError = message || "Could not connect to the enterprise network.";
        enterpriseBusy = false;
        enterpriseStage = "";
        pendingSecret = "";
        if (secretReady)
            secretFile.setText("");
    }

    property FileView secretFile: FileView {
        path: root.secretReady ? root.secretPath : ""
        blockWrites: true
        atomicWrites: false
        onSaved: {
            if (root.enterpriseStage !== "writing-secret")
                return;
            root.pendingSecret = "";
            root.enterpriseStage = "creating-profile";
            createProfile.exec(["nmcli", "connection", "add", "type", "wifi", "ifname", root.enterpriseNetwork.device.name, "con-name", root.enterpriseProfile, "ssid", root.enterpriseNetwork.name]);
        }
    }

    property Process prepareSecret: Process {
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.failEnterprise("Could not create a secure credential handoff.");
                return;
            }
            root.secretReady = true;
            root.enterpriseStage = "writing-secret";
            Qt.callLater(() => root.secretFile.setText(root.enterpriseSecretKey + ":" + root.pendingSecret + "\n"));
        }
    }
    property Process createProfile: Process {
        stderr: StdioCollector {
            id: createError
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.failEnterprise(createError.text.trim());
                return;
            }
            const args = ["nmcli", "connection", "modify", root.enterpriseProfile, "wifi-sec.key-mgmt", root.enterpriseNetwork.security === WifiSecurityType.Wpa3SuiteB192 ? "wpa-eap-suite-b-192" : "wpa-eap", "802-1x.eap", root.enterpriseMethod, "802-1x.identity", root.enterpriseIdentity];
            if (root.enterpriseMethod === "tls") {
                args.push("802-1x.client-cert", root.enterpriseClientCertificate, "802-1x.private-key", root.enterprisePrivateKey, "802-1x.private-key-password-flags", "2");
            } else {
                args.push("802-1x.phase2-auth", root.enterprisePhase2, "802-1x.password-flags", "2");
            }
            if (root.enterpriseCaCertificate !== "")
                args.push("802-1x.ca-cert", root.enterpriseCaCertificate);
            if (root.enterpriseDomain !== "")
                args.push("802-1x.domain-suffix-match", root.enterpriseDomain);
            if (root.enterpriseAnonymousIdentity !== "")
                args.push("802-1x.anonymous-identity", root.enterpriseAnonymousIdentity);
            root.enterpriseStage = "configuring-profile";
            configureProfile.exec(args);
        }
    }
    property Process configureProfile: Process {
        stderr: StdioCollector {
            id: configureError
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.failEnterprise(configureError.text.trim());
                return;
            }
            root.enterpriseStage = "connecting";
            activateProfile.exec(["nmcli", "--passwd-file", root.secretPath, "connection", "up", root.enterpriseProfile]);
        }
    }
    property Process activateProfile: Process {
        stderr: StdioCollector {
            id: activateError
        }
        onExited: (exitCode, exitStatus) => {
            root.secretFile.setText("");
            root.enterpriseStage = "";
            root.enterpriseBusy = false;
            root.enterpriseError = exitCode === 0 ? "" : activateError.text.trim();
        }
    }
}
