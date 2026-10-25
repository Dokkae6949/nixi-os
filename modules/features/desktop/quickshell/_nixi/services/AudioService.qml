pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire
import ".."

QtObject {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink, root.source].filter(object => object !== null)
    }
    function toggleOutputMute(): void {
        if (sink?.audio !== undefined)
            sink.audio.muted = !sink.audio.muted;
    }
}
