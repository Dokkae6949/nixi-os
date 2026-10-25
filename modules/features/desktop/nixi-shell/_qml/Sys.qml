pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// CPU, memory, backlight and power profile. Read straight from procfs/sysfs
// on one slow timer; no subprocesses. Brightness is written back through
// sysfs as well (brightnessctl's udev rule makes it writable for `video`);
// the write's inotify event updates the bar and OSD right away.
Singleton {
    id: root

    property int cpu: 0
    property int mem: 0
    property real brightness: -1
    property real lastIdle: 0
    property real lastTotal: 0
    readonly property string backlight: "/sys/class/backlight/intel_backlight"

    readonly property int profile: PowerProfiles.profile
    readonly property string profileName: PowerProfile.toString(profile)

    function cycleProfile(): void {
        if (profile === PowerProfile.PowerSaver)
            PowerProfiles.profile = PowerProfile.Balanced;
        else if (profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile)
            PowerProfiles.profile = PowerProfile.Performance;
        else
            PowerProfiles.profile = PowerProfile.PowerSaver;
    }

    // Never goes fully dark: 1% is the floor.
    function stepBrightness(percent: int): void {
        const max = Number(maxLevel.text()) || 0;
        if (max <= 0 || brightness < 0)
            return;
        const target = Math.max(1, Math.min(100, Math.round(brightness * 100) + percent));
        const raw = Math.max(1, Math.round(target / 100 * max));
        level.setText(String(raw));
        // Update now so key repeat steps from the new value, not a stale one.
        brightness = raw / max;
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            level.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().slice(0, text().indexOf("\n")).split(/\s+/).slice(1, 9).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastTotal > 0 && total > root.lastTotal)
                root.cpu = Math.round(100 * (1 - (idle - root.lastIdle) / (total - root.lastTotal)));
            root.lastIdle = idle;
            root.lastTotal = total;
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(/MemTotal:\s+(\d+)/.exec(t)[1]);
            const avail = Number(/MemAvailable:\s+(\d+)/.exec(t)[1]);
            root.mem = Math.round(100 * (1 - avail / total));
        }
    }

    FileView {
        id: maxLevel
        path: root.backlight + "/max_brightness"
    }

    FileView {
        id: level
        path: root.backlight + "/brightness"
        // sysfs attributes cannot be replaced by a rename.
        atomicWrites: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const max = Number(maxLevel.text()) || 0;
            root.brightness = max > 0 ? Number(text()) / max : -1;
        }
    }
}
