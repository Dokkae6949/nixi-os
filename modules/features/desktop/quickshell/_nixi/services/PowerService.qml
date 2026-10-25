pragma Singleton
import QtQuick
import Quickshell.Services.UPower
import ".."

QtObject {
    id: root
    readonly property var displayBattery: UPower.displayDevice
    readonly property bool available: displayBattery.ready && displayBattery.isPresent
    readonly property int percent: Math.round(displayBattery.percentage * 100)
    readonly property bool charging: displayBattery.state === UPowerDeviceState.Charging
    readonly property var laptopBatteries: {
        const result = [];
        for (const device of UPower.devices.values) {
            if (device.ready && device.isPresent && device.isLaptopBattery)
                result.push(device);
        }
        return result.slice(0, 2);
    }

    readonly property int confirmedProfile: PowerProfiles.profile
    property int requestedProfile: PowerProfiles.profile
    property bool profileRequestPending: false
    readonly property int profile: profileRequestPending ? requestedProfile : confirmedProfile
    readonly property string profileId: profile === PowerProfile.PowerSaver ? "saver"
                                                : profile === PowerProfile.Performance ? "performance"
                                                                                      : "balanced"
    readonly property string profileLabel: profile === PowerProfile.PowerSaver ? "Saver"
                                                   : profile === PowerProfile.Performance ? "Performance"
                                                                                         : "Balanced"
    readonly property string profileIcon: profile === PowerProfile.PowerSaver ? "nixi-power-saver-symbolic"
                                                  : profile === PowerProfile.Performance ? "nixi-power-performance-symbolic"
                                                                                        : "nixi-power-balanced-symbolic"
    property bool profileFeedbackEnabled: false

    function setProfile(name: string): bool {
        const normalized = name.trim().toLowerCase();
        let nextProfile;
        if (normalized === "saver" || normalized === "power-saver")
            nextProfile = PowerProfile.PowerSaver;
        else if (normalized === "balanced")
            nextProfile = PowerProfile.Balanced;
        else if (normalized === "performance" && PowerProfiles.hasPerformanceProfile)
            nextProfile = PowerProfile.Performance;
        else
            return false;

        requestedProfile = nextProfile;
        profileRequestPending = true;
        applyProfile.restart();
        reconciliationTimeout.restart();
        PopupController.showMessage(profileIcon, "Power profile", profileLabel);
        return true;
    }

    function cycleProfile(): bool {
        if (profile === PowerProfile.PowerSaver)
            return setProfile("balanced");
        if (profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile)
            return setProfile("performance");
        return setProfile("saver");
    }

    property Timer feedbackDelay: Timer {
        running: true
        interval: 1000
        onTriggered: root.profileFeedbackEnabled = true
    }

    // Several rapid key presses update requestedProfile immediately but result
    // in one D-Bus write for the final choice. This prevents cycling from using
    // the daemon's delayed previous value.
    property Timer applyProfile: Timer {
        interval: 150
        onTriggered: {
            // Write even when the last confirmed value happens to match: an
            // older request may still be queued at the daemon, and this final
            // write must win.
            PowerProfiles.profile = root.requestedProfile;
        }
    }

    property Timer reconciliationTimeout: Timer {
        interval: 2500
        onTriggered: {
            root.profileRequestPending = false;
            root.requestedProfile = root.confirmedProfile;
        }
    }

    property Connections profileSignals: Connections {
        target: PowerProfiles
        function onProfileChanged(): void {
            const wasPending = root.profileRequestPending;
            if (root.profileRequestPending
                    && root.confirmedProfile === root.requestedProfile) {
                root.profileRequestPending = false;
                root.reconciliationTimeout.stop();
            } else if (!root.profileRequestPending) {
                root.requestedProfile = root.confirmedProfile;
            }
            if (!wasPending && root.profileFeedbackEnabled)
                PopupController.showMessage(root.profileIcon, "Power profile", root.profileLabel);
        }
    }
}
