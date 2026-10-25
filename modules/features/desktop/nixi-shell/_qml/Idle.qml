import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// When the session locks, blanks and sleeps on its own. Idle timers respect
// idle inhibitors, so a playing video keeps everything awake.
//
//   5 min idle          lock
//   +30 s while locked  displays off (any input turns them back on)
//   15 min / 30 min     suspend on battery / on AC
//
// Lid close, `systemctl suspend` and `loginctl lock-session` go through
// logind: a delay inhibitor keeps the machine awake until the lock surface is
// up, so the desktop never flashes on resume.
Scope {
    id: root

    readonly property int lockAfter: 5 * 60
    readonly property int blankAfter: 30
    readonly property int suspendAfter: (Battery.onBattery ? 15 : 30) * 60

    property bool sleeping: false

    IdleMonitor {
        timeout: root.lockAfter
        onIsIdleChanged: if (isIdle) Session.lock()
    }

    IdleMonitor {
        enabled: Session.locked
        timeout: root.blankAfter
        onIsIdleChanged: if (isIdle) Session.run(["niri", "msg", "action", "power-off-monitors"])
    }

    IdleMonitor {
        timeout: root.suspendAfter
        onIsIdleChanged: if (isIdle) Session.run(["systemctl", "suspend"])
    }

    // Holds the sleep delay lock until a line arrives on stdin; re-taken on
    // resume.
    Process {
        id: inhibitor
        running: true
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=Nixi Shell", "--why=Lock the screen before sleep", "head", "-n1"]
        onRunningChanged: if (!running && !root.sleeping) retake.start()
    }

    Timer {
        id: retake
        interval: 1000
        onTriggered: inhibitor.running = true
    }

    // Give the lock surface a frame to land before letting the machine go.
    Timer {
        id: release
        interval: 150
        onTriggered: if (inhibitor.running) inhibitor.write("\n")
    }

    Connections {
        target: Session
        function onSecureChanged(): void {
            if (root.sleeping && Session.secure)
                release.restart();
        }
    }

    Process {
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes(".Manager.PrepareForSleep (true")) {
                    root.sleeping = true;
                    Session.lock();
                    if (Session.secure)
                        release.restart();
                } else if (line.includes(".Manager.PrepareForSleep (false")) {
                    root.sleeping = false;
                    inhibitor.running = true;
                } else if (line.includes(".Session.Lock ()")) {
                    Session.lock();
                }
            }
        }
    }
}
