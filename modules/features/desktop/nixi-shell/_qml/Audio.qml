pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink and source through the native PipeWire service. Volume keys
// come in over IPC and land here, so the bar and OSD see every change.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool hasSink: sink?.audio !== undefined && sink?.audio !== null
    readonly property bool hasMic: source?.audio !== undefined && source?.audio !== null
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    function stepVolume(percent: int): void {
        if (!hasSink)
            return;
        if (percent > 0)
            sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, Math.round(volume * 100 + percent) / 100));
    }

    function toggleMute(): void {
        if (hasSink)
            sink.audio.muted = !muted;
    }

    function toggleMic(): void {
        if (hasMic)
            source.audio.muted = !micMuted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
