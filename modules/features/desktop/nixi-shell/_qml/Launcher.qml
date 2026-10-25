import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// App launcher with session commands, plus cliphist history in "clipboard"
// mode. Created on open and destroyed on close, so it costs nothing idle.
PanelWindow {
    id: root

    readonly property bool clipboard: Ui.panel === "clipboard"
    property string query: ""
    property var clips: []

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "nixi-shell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onClipboardChanged: reset()
    Component.onCompleted: reset()

    function reset(): void {
        query = "";
        input.text = "";
        list.currentIndex = 0;
        if (clipboard && !cliphist.running)
            cliphist.running = true;
    }

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .map(a => ({
            name: a.name,
            sub: a.genericName || a.comment,
            icon: Quickshell.iconPath(a.icon, "application-x-executable"),
            glyph: "",
            key: a.name.toLowerCase(),
            hay: [a.genericName, a.comment, a.execString, a.id].concat(a.keywords).join(" ").toLowerCase(),
            run: () => a.execute()
        }))
        .sort((x, y) => x.key.localeCompare(y.key))

    function command(name: string, glyph: string, run: var): var {
        return { name: name, sub: "Command", icon: "", glyph: glyph, key: name.toLowerCase(), hay: "", run: run };
    }

    readonly property var commands: [
        command("Lock", "\u{F033E}", () => Session.lock()),
        command("Suspend", "\u{F04B2}", () => Session.run(["systemctl", "suspend"])),
        command("Log out", "\u{F0343}", () => Session.run(["niri", "msg", "action", "quit", "--skip-confirmation"])),
        command("Reboot", "\u{F0709}", () => Session.run(["systemctl", "reboot"])),
        command("Shut down", "\u{F0425}", () => Session.run(["systemctl", "poweroff"])),
        command("Do not disturb", "\u{F009B}", () => Notifs.toggleDnd()),
        command("Power profile", "\u{F05D1}", () => Sys.cycleProfile()),
        command("Clipboard", "\u{F014C}", () => Qt.callLater(() => Ui.panel = "clipboard"))
    ]

    // 0 = name prefix, 1 = word prefix, 2 = name substring, 3 = other fields.
    function score(item: var, q: string): int {
        const at = item.key.indexOf(q);
        if (at === 0)
            return 0;
        if (at > 0)
            return item.key.indexOf(" " + q) >= 0 ? 1 : 2;
        return item.hay.indexOf(q) >= 0 ? 3 : -1;
    }

    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (clipboard)
            return q === "" ? clips : clips.filter(c => c.key.indexOf(q) >= 0);
        if (q === "")
            return apps;
        const scored = [];
        for (const item of commands.concat(apps)) {
            const s = score(item, q);
            if (s >= 0)
                scored.push({ s: s, item: item });
        }
        scored.sort((a, b) => a.s - b.s || a.item.key.localeCompare(b.item.key));
        return scored.slice(0, 50).map(x => x.item);
    }

    function activate(): void {
        const item = results[list.currentIndex];
        if (!item)
            return;
        Ui.panel = "";
        item.run();
    }

    function removeClip(): void {
        const item = results[list.currentIndex];
        if (!clipboard || !item)
            return;
        Session.run(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", item.raw]);
        clips = clips.filter(c => c !== item);
    }

    Process {
        id: cliphist
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clips = text.split("\n").filter(l => l.indexOf("\t") > 0).map(line => {
                    const preview = line.slice(line.indexOf("\t") + 1);
                    return {
                        name: preview.replace(/\s+/g, " "),
                        sub: "",
                        icon: "",
                        glyph: "",
                        key: preview.toLowerCase(),
                        raw: line,
                        run: () => Session.run(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "sh", line])
                    };
                });
            }
        }
    }

    // Click outside closes.
    MouseArea {
        anchors.fill: parent
        onClicked: Ui.panel = ""
    }

    Rectangle {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.18)
        width: 600
        height: 44 + Math.min(list.contentHeight, 10 * 40) + (list.count > 0 ? Theme.gap : 0) + Theme.borderWidth * 2
        color: Theme.bg
        border.width: Theme.borderWidth
        border.color: Theme.accent

        MouseArea {
            anchors.fill: parent
        }

        TextInput {
            id: input
            x: 14
            y: Theme.borderWidth
            width: parent.width - 28
            height: 42
            verticalAlignment: TextInput.AlignVCenter
            focus: true
            color: Theme.fg
            selectionColor: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 2
            onTextEdited: {
                root.query = text;
                list.currentIndex = 0;
            }
            onAccepted: root.activate()

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (event.key === Qt.Key_Escape) {
                    Ui.panel = "";
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                    list.incrementCurrentIndex();
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                    list.decrementCurrentIndex();
                } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                    root.removeClip();
                } else {
                    return;
                }
                event.accepted = true;
            }

            Text {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.clipboard ? "Clipboard (Shift+Del removes)" : "Run…"
                color: Theme.muted
                font: input.font
            }
        }

        Rectangle {
            visible: list.count > 0
            x: Theme.borderWidth
            y: 44
            width: parent.width - Theme.borderWidth * 2
            height: Theme.borderWidth
            color: Theme.border
        }

        ListView {
            id: list
            x: Theme.borderWidth
            y: 44 + Theme.gap
            width: parent.width - Theme.borderWidth * 2
            height: parent.height - y - Theme.borderWidth
            clip: true
            model: root.results
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            reuseItems: true

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 40
                color: ListView.isCurrentItem ? Theme.bg1 : "transparent"

                Rectangle {
                    visible: row.ListView.isCurrentItem
                    width: 3
                    height: parent.height
                    color: Theme.accent
                }

                Image {
                    id: icon
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    sourceSize.width: 24
                    sourceSize.height: 24
                    source: row.modelData.icon
                    visible: row.modelData.icon !== ""
                    asynchronous: true
                }
                Text {
                    visible: row.modelData.glyph !== ""
                    anchors.centerIn: icon
                    text: row.modelData.glyph
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 18
                }

                Text {
                    x: root.clipboard ? 14 : 48
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - 14
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: row.modelData.name + (row.modelData.sub ? "   " : "")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize

                    Text {
                        x: parent.implicitWidth
                        width: Math.max(0, parent.width - x)
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: row.modelData.sub || ""
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: list.currentIndex = row.index
                    onClicked: {
                        list.currentIndex = row.index;
                        root.activate();
                    }
                }
            }
        }
    }
}
