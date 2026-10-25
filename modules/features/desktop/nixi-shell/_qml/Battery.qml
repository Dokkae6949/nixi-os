pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Combined state of both packs plus low-battery warnings.
//
// With two batteries the firmware drains one pack after the other, so a single
// pack being low means nothing (and the idle one sits in "not charging" rather
// than "discharging"). Warnings therefore follow UPower's energy-weighted
// display device and the AC state, not any individual pack.
Singleton {
    id: root

    readonly property UPowerDevice total: UPower.displayDevice
    readonly property bool present: total.ready && total.isPresent
    readonly property int percent: Math.round(total.percentage * 100)
    readonly property bool onBattery: UPower.onBattery
    readonly property bool charging: total.state === UPowerDeviceState.Charging
    readonly property real seconds: onBattery ? total.timeToEmpty : charging ? total.timeToFull : 0
    readonly property var packs: UPower.devices.values
        .filter(d => d.isLaptopBattery && d.isPresent)
        .sort((a, b) => a.nativePath.localeCompare(b.nativePath))

    readonly property int lowPercent: 15
    readonly property int criticalPercent: 5
    // Lowest threshold already announced during this discharge.
    property int warnedAt: 101

    function duration(s: real): string {
        if (s <= 0)
            return "";
        const m = Math.round(s / 60);
        return Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0");
    }

    function packSummary(): string {
        return packs.map(p => p.nativePath + " " + Math.round(p.percentage * 100) + "%").join(", ");
    }

    function check(): void {
        if (!present)
            return;
        if (!onBattery) {
            if (warnedAt <= 100)
                Notifs.withdraw("battery");
            warnedAt = 101;
            return;
        }
        const level = percent <= criticalPercent ? criticalPercent : percent <= lowPercent ? lowPercent : 101;
        if (level >= warnedAt)
            return;
        warnedAt = level;
        if (level > 100)
            return;
        const left = duration(total.timeToEmpty);
        Notifs.post(level === criticalPercent ? "Battery critical: " + percent + "%" : "Battery low: " + percent + "%",
                    (left ? "About " + left + " left. " : "") + packSummary() + ". Plug in soon.",
                    true, "battery");
    }

    // Detailed status on demand (battery click in the bar).
    function report(): void {
        const lines = packs.map(p => p.nativePath + ": " + Math.round(p.percentage * 100) + "% · " + UPowerDeviceState.toString(p.state)
                                + (p.healthSupported ? " · health " + Math.round(p.healthPercentage <= 1 ? p.healthPercentage * 100 : p.healthPercentage) + "%" : "")
                                + (p.changeRate !== 0 ? " · " + Math.abs(p.changeRate).toFixed(1) + " W" : ""));
        const eta = duration(seconds);
        Notifs.post("Battery " + percent + "%" + (eta ? " · " + eta + (onBattery ? " left" : " to full") : "") + (onBattery ? "" : " · on AC"),
                    lines.join("\n"), false, "battery-report");
    }

    Connections {
        target: root.total
        function onPercentageChanged(): void { root.check(); }
        function onReadyChanged(): void { root.check(); }
    }
    Connections {
        target: UPower
        function onOnBatteryChanged(): void { root.check(); }
    }
    // Safety net in case a property change is missed (e.g. across suspend).
    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
}
