import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import ".."
import "../components"

Item {
    id: root
    property var selectedNetwork: null
    property string promptMode: ""
    property string enterpriseMethod: "peap"
    property string enterprisePhase2: "mschapv2"

    function choose(network): void {
        selectedNetwork = network;
        NetworkService.enterpriseError = "";
        if (network.connected || network.known || !NetworkService.requiresPassword(network) && !NetworkService.isEnterprise(network)) {
            NetworkService.connectNetwork(network, "");
        } else {
            promptMode = NetworkService.isEnterprise(network) ? "enterprise" : "password";
            if (network.security === WifiSecurityType.Wpa3SuiteB192)
                enterpriseMethod = "tls";
            Qt.callLater(() => {
                if (promptMode === "enterprise")
                    identityField.focusInput();
                else
                    passwordField.focusInput();
            });
        }
    }

    function closePrompt(): void {
        promptMode = "";
        selectedNetwork = null;
        passwordField.clear();
        identityField.clear();
        enterprisePassword.clear();
        anonymousIdentity.clear();
        caCertificate.clear();
        clientCertificate.clear();
        privateKey.clear();
        domainSuffix.clear();
    }

    function select(index: int): void {
        if (networkList.count === 0)
            return;
        networkList.currentIndex = Math.max(0, Math.min(networkList.count - 1, index));
        networkList.positionViewAtIndex(networkList.currentIndex, ListView.Contain);
    }

    onEnabledChanged: NetworkService.setScanning(enabled && Networking.wifiEnabled)

    Connections {
        target: Networking
        function onWifiEnabledChanged(): void {
            NetworkService.setScanning(root.enabled && Networking.wifiEnabled);
        }
    }

    Connections {
        target: NetworkService
        function onEnterpriseBusyChanged(): void {
            if (!NetworkService.enterpriseBusy && NetworkService.enterpriseError === "" && root.promptMode === "enterprise")
                root.closePrompt();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        ConnectivityHeader {
            Layout.fillWidth: true
            title: "Wi-Fi"
            subtitle: NetworkService.wifiConnected ? "Connected to " + NetworkService.wifiNetwork.name : Networking.wifiEnabled ? "Choose a network" : "Wireless is off"
            iconName: Networking.wifiEnabled ? "network-wireless-symbolic" : "network-wireless-offline-symbolic"
            radioEnabled: Networking.wifiEnabled
            radioAvailable: Networking.wifiHardwareEnabled
            onToggled: NetworkService.toggleWifi()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusPanel
            color: Theme.surfaceRaised
            clip: true

            ListView {
                id: networkList
                anchors.fill: parent
                anchors.margins: Theme.spaceSm
                spacing: Theme.spaceXs
                clip: true
                model: Networking.wifiEnabled ? NetworkService.wifiNetworks : []
                onCountChanged: if (count > 0 && currentIndex < 0)
                    currentIndex = 0

                delegate: Rectangle {
                    id: networkRow
                    required property var modelData
                    width: ListView.view.width
                    height: 54
                    radius: Theme.radiusSm
                    color: modelData.connected ? Theme.background : ListView.isCurrentItem || rowHover.hovered ? Theme.surface : "transparent"

                    Connections {
                        target: modelData
                        function onConnectionFailed(reason): void {
                            root.selectedNetwork = modelData;
                            NetworkService.enterpriseError = ConnectionFailReason.toString(reason);
                            root.promptMode = NetworkService.isEnterprise(modelData) ? "enterprise" : "password";
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spaceMd
                        anchors.rightMargin: Theme.spaceMd
                        spacing: Theme.spaceMd
                        WifiIcon {
                            connected: true
                            strength: NetworkService.normalizedStrength(modelData.signalStrength)
                            size: Theme.iconMedium
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || "Hidden network"
                                color: Theme.foreground
                                font.pixelSize: Theme.fontBody
                                font.weight: modelData.connected ? Font.Bold : Theme.fontWeightMedium
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.stateChanging ? ConnectionState.toString(modelData.state) : modelData.connected ? "Connected" : (modelData.known ? "Saved · " : "") + NetworkService.securityLabel(modelData)
                                color: modelData.connected ? Theme.accent : Theme.foregroundMuted
                                font.pixelSize: Theme.fontSmall
                            }
                        }
                        Text {
                            visible: modelData.stateChanging
                            text: "…"
                            color: Theme.accent
                            font.pixelSize: Theme.fontTitle
                        }
                        NixiIcon {
                            visible: !modelData.stateChanging
                            name: modelData.connected ? "window-close-symbolic" : "media-playback-start-symbolic"
                            size: Theme.iconSmall
                            color: Theme.foregroundMuted
                        }
                    }
                    HoverHandler {
                        id: rowHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered)
                            networkList.currentIndex = index
                    }
                    TapHandler {
                        onTapped: root.choose(modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: networkList.count === 0
                    text: Networking.wifiEnabled ? "Scanning for networks…" : "Turn on Wi-Fi to discover networks"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontBody
                }

                WheelHandler {
                    target: networkList
                }
            }

            ListNavigation {
                list: networkList
                active: root.enabled && root.promptMode === ""
                onActivated: index => root.choose(networkList.model[index])
            }
        }
    }

    Rectangle {
        visible: root.promptMode !== ""
        anchors.fill: parent
        color: "#99000000"
        z: 10
        TapHandler {
            onTapped: root.closePrompt()
        }

        BaseSurface {
            anchors.centerIn: parent
            width: Math.min(420, parent.width - Theme.spaceXl * 2)
            height: promptContent.implicitHeight + Theme.spaceXl * 2
            radius: Theme.radiusPanel
            TapHandler {
                onTapped: function () {}
            }

            ColumnLayout {
                id: promptContent
                anchors.fill: parent
                anchors.margins: Theme.spaceXl
                spacing: Theme.spaceMd

                Text {
                    Layout.fillWidth: true
                    text: root.selectedNetwork ? "Connect to " + root.selectedNetwork.name : "Connect"
                    color: Theme.foreground
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                TextEntry {
                    id: passwordField
                    visible: root.promptMode === "password"
                    Layout.fillWidth: true
                    placeholder: "Network password"
                    password: true
                    onAccepted: {
                        NetworkService.connectNetwork(root.selectedNetwork, text);
                        root.closePrompt();
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.promptMode === "password" && NetworkService.enterpriseError !== ""
                    text: NetworkService.enterpriseError
                    color: Theme.critical
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    visible: root.promptMode === "enterprise"
                    Layout.fillWidth: true
                    spacing: Theme.spaceSm

                    RowLayout {
                        spacing: Theme.spaceSm
                        ActionButton {
                            label: "PEAP"
                            accent: root.enterpriseMethod === "peap"
                            onClicked: root.enterpriseMethod = "peap"
                        }
                        ActionButton {
                            label: "TTLS"
                            accent: root.enterpriseMethod === "ttls"
                            onClicked: root.enterpriseMethod = "ttls"
                        }
                        ActionButton {
                            label: "TLS"
                            accent: root.enterpriseMethod === "tls"
                            onClicked: root.enterpriseMethod = "tls"
                        }
                    }

                    TextEntry {
                        id: identityField
                        Layout.fillWidth: true
                        placeholder: "Identity / username"
                    }
                    TextEntry {
                        id: anonymousIdentity
                        visible: root.enterpriseMethod !== "tls"
                        Layout.fillWidth: true
                        placeholder: "Anonymous identity (optional)"
                    }
                    TextEntry {
                        id: enterprisePassword
                        Layout.fillWidth: true
                        placeholder: root.enterpriseMethod === "tls" ? "Private-key password (optional)" : "Password"
                        password: true
                    }
                    RowLayout {
                        visible: root.enterpriseMethod !== "tls"
                        spacing: Theme.spaceSm
                        Text {
                            text: "Inner auth"
                            color: Theme.foregroundMuted
                            font.pixelSize: Theme.fontSmall
                        }
                        ActionButton {
                            label: "MSCHAPv2"
                            accent: root.enterprisePhase2 === "mschapv2"
                            onClicked: root.enterprisePhase2 = "mschapv2"
                        }
                        ActionButton {
                            label: "PAP"
                            accent: root.enterprisePhase2 === "pap"
                            onClicked: root.enterprisePhase2 = "pap"
                        }
                    }
                    TextEntry {
                        id: caCertificate
                        visible: root.enterpriseMethod === "tls"
                        Layout.fillWidth: true
                        placeholder: "CA certificate path (optional)"
                    }
                    TextEntry {
                        id: clientCertificate
                        visible: root.enterpriseMethod === "tls"
                        Layout.fillWidth: true
                        placeholder: "Client certificate path"
                    }
                    TextEntry {
                        id: privateKey
                        visible: root.enterpriseMethod === "tls"
                        Layout.fillWidth: true
                        placeholder: "Private key path"
                    }
                    TextEntry {
                        id: domainSuffix
                        Layout.fillWidth: true
                        placeholder: "Server domain suffix (recommended)"
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: NetworkService.enterpriseError !== ""
                        text: NetworkService.enterpriseError
                        color: Theme.critical
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.Wrap
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item {
                        Layout.fillWidth: true
                    }
                    ActionButton {
                        label: "Cancel"
                        onClicked: root.closePrompt()
                    }
                    ActionButton {
                        label: NetworkService.enterpriseBusy ? "Connecting…" : "Connect"
                        accent: true
                        enabled: !NetworkService.enterpriseBusy && (root.promptMode === "password" ? passwordField.text !== "" : identityField.text !== "" && (root.enterpriseMethod === "tls" ? clientCertificate.text !== "" && privateKey.text !== "" : enterprisePassword.text !== ""))
                        onClicked: {
                            if (root.promptMode === "password") {
                                NetworkService.connectNetwork(root.selectedNetwork, passwordField.text);
                                root.closePrompt();
                            } else {
                                NetworkService.connectEnterprise(root.selectedNetwork, identityField.text, enterprisePassword.text, root.enterpriseMethod, root.enterprisePhase2, anonymousIdentity.text, caCertificate.text, clientCertificate.text, privateKey.text, domainSuffix.text);
                                enterprisePassword.clear();
                            }
                        }
                    }
                }
            }
        }
    }
}
