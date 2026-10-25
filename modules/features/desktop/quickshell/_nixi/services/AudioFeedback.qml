pragma Singleton
import QtQuick
import ".."

QtObject {
    id: root
    property bool enabled: false
    function start(): void { delay.restart(); }
    property Timer delay: Timer { interval: 1000; onTriggered: root.enabled = true }

    property Connections outputSignals: Connections {
        target: AudioService.sink?.audio ?? null
        function onVolumesChanged(): void {
            if (root.enabled)
                PopupController.showOsd(AudioService.sink.audio.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic",
                                        "Volume", AudioService.sink.audio.volume, "level");
        }
        function onMutedChanged(): void {
            if (root.enabled)
                PopupController.showOsd(AudioService.sink.audio.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic",
                                        AudioService.sink.audio.muted ? "Speaker muted" : "Speaker",
                                        AudioService.sink.audio.volume, "level");
        }
    }
    property Connections inputSignals: Connections {
        target: AudioService.source?.audio ?? null
        function onVolumesChanged(): void {
            if (root.enabled)
                PopupController.showOsd(AudioService.source.audio.muted ? "microphone-disabled-symbolic" : "microphone-sensitivity-high-symbolic",
                                        "Microphone", AudioService.source.audio.volume, "level");
        }
        function onMutedChanged(): void {
            if (root.enabled)
                PopupController.showOsd(AudioService.source.audio.muted ? "microphone-disabled-symbolic" : "microphone-sensitivity-high-symbolic",
                                        AudioService.source.audio.muted ? "Microphone muted" : "Microphone",
                                        AudioService.source.audio.volume, "level");
        }
    }
}
