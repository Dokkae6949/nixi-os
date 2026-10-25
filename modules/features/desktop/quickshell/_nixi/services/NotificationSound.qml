pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import ".."

QtObject {
    readonly property string criticalSound: settings.criticalSound

    function criticalSoundPath(name: string): string {
        switch (name) {
        case "soft-error": return "assets/audio/critical.ogg";
        case "plucky": return "assets/audio/critical-plucky.ogg";
        case "echoed-ding": return "assets/audio/critical-echoed-ding.ogg";
        default: return "assets/audio/critical-short-notice.ogg";
        }
    }

    function validCriticalSound(name: string): bool {
        return name === "short-notice" || name === "plucky"
               || name === "echoed-ding" || name === "soft-error";
    }

    function setCriticalSound(name: string): void {
        if (validCriticalSound(name))
            settings.criticalSound = name;
    }

    function playPath(path: string): void {
        player.exec([
            "pw-play", "--volume", String(Settings.notificationVolume),
            Quickshell.shellPath(path)
        ]);
    }

    function preview(name: string): void {
        if (validCriticalSound(name))
            playPath(criticalSoundPath(name));
    }

    function play(urgency: int, muted: bool): void {
        if (muted)
            return;
        playPath(urgency === NotificationUrgency.Critical
                 ? criticalSoundPath(criticalSound)
                 : "assets/audio/notify.oga");
    }

    property PersistentProperties settings: PersistentProperties {
        reloadableId: "notificationAudio"
        property string criticalSound: Settings.defaultCriticalNotificationSound
    }

    property Process player: Process {}
}
