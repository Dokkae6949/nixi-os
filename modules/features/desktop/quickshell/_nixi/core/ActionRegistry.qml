pragma Singleton
import QtQuick
import ".."

// Shared action catalog for the launcher and IPC. IDs describe intent rather
// than the UI control that happened to invoke them.
QtObject {
    readonly property var entries: [
        {
            id: "surface.toggle",
            label: "Toggle surface",
            icon: "view-more-symbolic",
            group: "Surface"
        },
        {
            id: "surface.close",
            label: "Close current view",
            icon: "window-close-symbolic",
            group: "Surface",
            keywords: "back escape dismiss"
        },
        {
            id: "open.home",
            label: "Home",
            icon: "view-restore-symbolic",
            group: "Views"
        },
        {
            id: "open.notifications",
            label: "Notifications",
            icon: "notification-symbolic",
            group: "Views"
        },
        {
            id: "open.battery",
            label: "Battery",
            icon: "battery-symbolic",
            group: "Views"
        },
        {
            id: "open.performance",
            label: "Performance monitor",
            icon: "speedometer-symbolic",
            group: "Views",
            keywords: "cpu memory ram storage disk temperature system metrics"
        },
        {
            id: "open.clipboard",
            label: "Clipboard history",
            icon: "edit-paste-symbolic",
            group: "Views",
            keywords: "cliphist copy paste text image"
        },
        {
            id: "open.launcher",
            label: "Search",
            icon: "system-search-symbolic",
            group: "Views",
            keywords: "launcher applications commands"
        },
        {
            id: "open.media",
            label: "Now playing",
            icon: "audio-x-generic-symbolic",
            group: "Views",
            keywords: "music player playback spotify"
        },
        {
            id: "open.wifi",
            label: "Wi-Fi networks",
            icon: "network-wireless-symbolic",
            group: "Connectivity",
            keywords: "internet wireless connect network wifi"
        },
        {
            id: "open.bluetooth",
            label: "Bluetooth devices",
            icon: "bluetooth-symbolic",
            group: "Connectivity",
            keywords: "pair connect discover device bt"
        },
        {
            id: "notifications.dnd.toggle",
            label: "Toggle Do Not Disturb",
            icon: "notifications-off-symbolic",
            group: "Notifications"
        },
        {
            id: "notifications.current.dismiss",
            label: "Dismiss notification",
            icon: "window-close-symbolic",
            group: "Notifications"
        },
        {
            id: "network.wifi.toggle",
            label: "Toggle Wi-Fi",
            icon: "network-wireless-symbolic",
            group: "Connectivity"
        },
        {
            id: "bluetooth.toggle",
            label: "Toggle Bluetooth",
            icon: "bluetooth-symbolic",
            group: "Connectivity"
        },
        {
            id: "audio.output.mute.toggle",
            label: "Toggle audio mute",
            icon: "audio-volume-muted-symbolic",
            group: "Audio"
        },
        {
            id: "power.profile.saver",
            label: "Power saver",
            icon: "battery-low-symbolic",
            group: "Power",
            keywords: "profile energy eco"
        },
        {
            id: "power.profile.balanced",
            label: "Balanced power",
            icon: "battery-good-symbolic",
            group: "Power",
            keywords: "profile normal"
        },
        {
            id: "power.profile.performance",
            label: "Performance mode",
            icon: "speedometer-symbolic",
            group: "Power",
            keywords: "profile fast"
        },
        {
            id: "session.lock",
            label: "Lock screen",
            icon: "system-lock-screen-symbolic",
            group: "Session"
        },
        {
            id: "session.suspend",
            label: "Suspend",
            icon: "system-suspend-symbolic",
            group: "Session",
            keywords: "sleep"
        },
        {
            id: "session.logout",
            label: "Log out",
            icon: "system-log-out-symbolic",
            group: "Session",
            keywords: "sign out quit"
        },
        {
            id: "session.reboot",
            label: "Restart",
            icon: "system-reboot-symbolic",
            group: "Session",
            keywords: "reboot"
        },
        {
            id: "session.poweroff",
            label: "Shut down",
            icon: "system-shutdown-symbolic",
            group: "Session",
            keywords: "power off shutdown"
        }
    ]

    function find(actionId: string): var {
        for (const entry of entries) {
            if (entry.id === actionId)
                return entry;
        }
        return null;
    }

    function select(actionIds: var): var {
        const selected = [];
        for (const actionId of actionIds) {
            const entry = find(actionId);
            if (entry !== null)
                selected.push(entry);
        }
        return selected;
    }

    function run(action: string, argument): bool {
        switch (action) {
        case "surface.toggle":
            SurfaceController.toggle();
            break;
        case "surface.reveal":
            SurfaceController.showHome();
            break;
        case "surface.conceal":
            SurfaceController.hide();
            break;
        case "surface.close":
            if (SurfaceController.overlayOpen)
                PopupController.dismissOverlay();
            else
                SurfaceController.close();
            break;
        case "surface.enabled.set":
            SurfaceController.setEnabled(Boolean(argument));
            break;
        case "open.home":
            SurfaceController.showHome();
            break;
        case "open.notifications":
            SurfaceController.open(SurfaceController.Notifications);
            if (SurfaceController.page === SurfaceController.Notifications)
                NotificationStore.markAllActiveSeen();
            break;
        case "open.battery":
            SurfaceController.open(SurfaceController.Battery);
            break;
        case "open.performance":
            SurfaceController.open(SurfaceController.systemMonitorPage);
            break;
        case "open.clipboard":
            SurfaceController.open(SurfaceController.clipboardPage);
            break;
        case "open.launcher":
            SurfaceController.open(SurfaceController.Launcher);
            break;
        case "open.media":
            SurfaceController.open(SurfaceController.mediaPage);
            break;
        case "open.wifi":
            SurfaceController.open(SurfaceController.wifiPage);
            break;
        case "open.bluetooth":
            SurfaceController.open(SurfaceController.bluetoothPage);
            break;
        case "notifications.dnd.toggle":
            NotificationStore.toggleDoNotDisturb();
            break;
        case "notifications.dnd.enable":
            NotificationStore.setDoNotDisturb(true);
            break;
        case "notifications.dnd.disable":
            NotificationStore.setDoNotDisturb(false);
            break;
        case "notifications.current.dismiss":
            NotificationStore.dismissCurrent();
            break;
        case "notifications.sound.preview":
            NotificationSound.preview(String(argument));
            break;
        case "notifications.sound.select":
            NotificationSound.setCriticalSound(String(argument));
            break;
        case "animation.toggle":
            Motion.enabled = !Motion.enabled;
            break;
        case "hardware.bluetooth-key":
            RadioFeedback.reportBluetoothKey();
            break;
        case "network.wifi.toggle":
            NetworkService.toggleWifi();
            break;
        case "bluetooth.toggle":
            BluetoothService.toggle();
            break;
        case "audio.output.mute.toggle":
            AudioService.toggleOutputMute();
            break;
        case "power.profile.set":
            return PowerService.setProfile(String(argument));
        case "power.profile.cycle":
            return PowerService.cycleProfile();
        case "power.profile.saver":
            return PowerService.setProfile("saver");
        case "power.profile.balanced":
            return PowerService.setProfile("balanced");
        case "power.profile.performance":
            return PowerService.setProfile("performance");
        case "session.lock":
            LockService.lock();
            break;
        case "session.suspend":
            SessionService.suspend();
            break;
        case "session.logout":
            SessionService.logout();
            break;
        case "session.reboot":
            SessionService.reboot();
            break;
        case "session.poweroff":
            SessionService.powerOff();
            break;
        default:
            return false;
        }
        return true;
    }
}
