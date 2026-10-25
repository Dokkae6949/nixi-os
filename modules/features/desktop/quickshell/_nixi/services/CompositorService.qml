pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

QtObject {
    id: root
    property bool started: false
    readonly property string socketPath: Quickshell.env("NIRI_SOCKET")
    function start(): void { started = true; }
    function handleEvent(line: string): void {
        if (line === "") return;
        try {
            const event = JSON.parse(line).OverviewOpenedOrClosed;
            if (event !== undefined)
                SurfaceController.setOverviewVisible(event.is_open === true);
        } catch (error) {}
    }
    property Socket eventSocket: Socket {
        path: root.socketPath
        connected: root.started && path !== ""
        onConnectionStateChanged: {
            if (connected) { write("\"EventStream\"\n"); flush(); }
            else SurfaceController.setOverviewVisible(false);
        }
        parser: SplitParser { onRead: data => root.handleEvent(data) }
    }
}
