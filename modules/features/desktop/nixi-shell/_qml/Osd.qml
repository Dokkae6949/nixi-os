import QtQuick
import Quickshell
import Quickshell.Wayland

// On-screen display for brightness, volume, microphone, Wi-Fi and Bluetooth.
// It reacts to the service state itself rather than to key presses, so
// changes from the bar, other apps or the hardware show up too. The bar
// jumps straight to the new level so it is never seen catching up.
PanelWindow {
    id: root

    // What to show; kept after hiding so the fade-out keeps its content.
    property string kind: ""
    property bool shown: false
    // Last seen value per kind. The services report their initial state
    // asynchronously, so a value only counts as a change once one is known
    // and the shell has settled.
    property var last: ({})
    property bool armed: false

    readonly property var info: {
        switch (kind) {
        case "brightness":
            return { icon: "\u{F00DF}", tint: Theme.yellow, title: "Brightness", value: Math.round(Sys.brightness * 100) + "%", level: Sys.brightness };
        case "volume":
            return Audio.muted
                ? { icon: Audio.icon, tint: Theme.muted, title: "Volume", value: "Muted", level: Audio.volume }
                : { icon: Audio.icon, tint: Theme.orange, title: "Volume", value: Math.round(Audio.volume * 100) + "%", level: Audio.volume };
        case "mic":
            return Audio.micMuted
                ? { icon: "\u{F036D}", tint: Theme.red, title: "Microphone", value: "Muted", level: -1 }
                : { icon: "\u{F036C}", tint: Theme.green, title: "Microphone", value: "Live", level: -1 };
        case "wifi":
            return !Radio.wifiEnabled
                ? { icon: "\u{F05AA}", tint: Theme.muted, title: "Wi-Fi", value: "Off", level: -1 }
                : Radio.link === null
                ? { icon: "\u{F092E}", tint: Theme.muted, title: "Wi-Fi", value: "Disconnected", level: -1 }
                : { icon: Radio.link.wired ? "\u{F0200}" : "\u{F0928}", tint: Theme.blue, title: Radio.link.wired ? "Network" : "Wi-Fi", value: Radio.link.name, level: -1 };
        case "bluetooth":
            return !Radio.btEnabled
                ? { icon: "\u{F00B2}", tint: Theme.muted, title: "Bluetooth", value: "Off", level: -1 }
                : { icon: Radio.btConnected.length > 0 ? "\u{F00B1}" : "\u{F00AF}", tint: Theme.blue, title: "Bluetooth", value: Radio.btNames || "On", level: -1 };
        }
        return null;
    }

    function observe(k: string, value: var): void {
        const known = k in last;
        const changed = last[k] !== value;
        last[k] = value;
        if (!known || !changed || !armed || Session.locked)
            return;
        kind = k;
        shown = true;
        hide.restart();
    }

    // The box is 320x60, 96px above the bottom; the rest is shadow room.
    anchors.bottom: true
    margins.bottom: 96 - Theme.shadowReach
    implicitWidth: 320 + Theme.shadowReach * 2
    implicitHeight: 60 + Theme.shadowReach * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "nixi-shell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Timer {
        id: hide
        interval: 1600
        onTriggered: root.shown = false
    }
    Timer {
        running: true
        interval: 3000
        onTriggered: root.armed = true
    }

    // Each binding re-runs when its source changes; observe() filters out
    // repeats of the same value.
    readonly property int brightness: Sys.brightness < 0 ? -1 : Math.round(Sys.brightness * 100)
    readonly property string volume: Audio.hasSink ? Math.round(Audio.volume * 100) + (Audio.muted ? "m" : "") : ""
    readonly property string mic: Audio.hasMic ? String(Audio.micMuted) : ""
    readonly property string wifi: Radio.wifiEnabled + "/" + Radio.linkName
    readonly property string bluetooth: Radio.adapter ? Radio.btEnabled + "/" + Radio.btNames : ""

    onBrightnessChanged: if (brightness >= 0) observe("brightness", brightness)
    onVolumeChanged: if (volume !== "") observe("volume", volume)
    onMicChanged: if (mic !== "") observe("mic", mic)
    onWifiChanged: observe("wifi", wifi)
    onBluetoothChanged: if (bluetooth !== "") observe("bluetooth", bluetooth)

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.shadowReach
        // The surface stays mapped (transparent, click-through); only the
        // content fades, so a quick re-trigger never recreates the window.
        opacity: root.shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: root.shown ? 80 : 180 }
        }
        color: Theme.bg
        border.width: Theme.borderWidth
        border.color: root.info?.tint ?? Theme.border

        // Below the box, fading with it.
        Shadow {
            anchors.fill: parent
            z: -1
        }

        Text {
            id: glyph
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            horizontalAlignment: Text.AlignHCenter
            text: root.info?.icon ?? ""
            color: root.info?.tint ?? Theme.fg
            font.family: Theme.font
            font.pixelSize: 26
        }

        Column {
            anchors.left: glyph.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Item {
                width: parent.width
                height: title.implicitHeight

                Text {
                    id: title
                    text: root.info?.title ?? ""
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    anchors.right: parent.right
                    width: Math.min(implicitWidth, parent.width - title.implicitWidth - 12)
                    horizontalAlignment: Text.AlignRight
                    text: root.info?.value ?? ""
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: (root.info?.level ?? -1) >= 0
                width: parent.width
                height: 6
                color: Theme.bg2

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.info?.level ?? 0))
                    height: parent.height
                    color: root.info?.tint ?? Theme.fg
                }
            }
        }
    }
}
