pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import ".."

QtObject {
    id: root
    property bool started: false
    property var currentWarning: null
    function start(): void {
        started = true;
        check();
    }
    function warned(index): bool {
        return index === 0 ? state.warned0 : state.warned1;
    }
    function setWarned(index, value): void {
        if (index === 0)
            state.warned0 = value;
        else
            state.warned1 = value;
    }
    function checkBattery(device, index): void {
        const percent = Math.round(device.percentage * 100);
        if (percent >= Settings.lowBatteryRearmPercent) {
            setWarned(index, false);
            return;
        }
        if (!started || device.state !== UPowerDeviceState.Discharging || warned(index) || percent > Settings.lowBatteryWarningPercent)
            return;
        setWarned(index, true);
        const name = device.nativePath || "Battery " + (index + 1);
        const model = device.model ? " (" + device.model + ")" : "";
        const sender = index === 0 ? sender0 : sender1;
        currentWarning = {
            summary: name + " low battery",
            body: percent + "% remaining" + model + ". Connect power soon.",
            image: "battery-caution-symbolic",
            critical: true
        };
        warningTimeout.restart();
        sender.exec(["notify-send", "--urgency=critical", "--app-name=Nixi", "--icon=battery-caution-symbolic", name + " low battery", percent + "% remaining" + model + ". Connect power soon."]);
    }
    function check(): void {
        const batteries = PowerService.laptopBatteries;
        for (let index = 0; index < Math.min(2, batteries.length); ++index)
            checkBattery(batteries[index], index);
    }
    property Process sender0: Process {}
    property Process sender1: Process {}
    property PersistentProperties state: PersistentProperties {
        reloadableId: "batteryWarnings"
        property bool warned0: false
        property bool warned1: false
    }
    property Timer poll: Timer {
        interval: 30000
        repeat: true
        running: root.started
        onTriggered: root.check()
    }
    property Timer warningTimeout: Timer {
        interval: Settings.notificationCriticalTimeout
        onTriggered: root.currentWarning = null
    }
}
