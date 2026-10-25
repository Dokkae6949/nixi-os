pragma Singleton
import QtQuick
import ".."

QtObject {
    property bool started: false
    function start(): void {
        if (started)
            return;
        started = true;
        BrightnessService.start();
        AudioFeedback.start();
        RadioFeedback.start();
        BatteryWarnings.start();
        CompositorService.start();
        SystemMetrics.start();
        BluetoothPairingService.start();
    }
}
