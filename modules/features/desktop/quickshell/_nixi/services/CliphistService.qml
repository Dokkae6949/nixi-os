pragma Singleton
import QtQuick
import Quickshell.Io
import ".."

QtObject {
    id: root
    property var entries: []
    property string previewSource: ""
    property string previewId: ""
    property string previewRaw: ""
    property string renderingPreviewId: ""
    readonly property string previewPath: "/tmp/nixi-cliphist-preview"

    function refresh(): void { if (!listing.running) listing.running = true; }
    function parse(text: string): void {
        const result = [];
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab < 1) continue;
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            result.push({ id: id, raw: line, preview: preview,
                          image: preview.indexOf("[[ binary data") === 0 });
        }
        entries = result;
    }
    function activate(entry): void {
        if (!entry) return;
        copy.command = ["bash", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "cliphist-copy", entry.raw];
        copy.running = true;
        SurfaceController.close();
    }
    function remove(entry): void {
        if (!entry) return;
        deletion.command = ["bash", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "cliphist-delete", entry.raw];
        deletion.running = true;
    }
    function loadPreview(entry): void {
        previewSource = "";
        previewId = entry && entry.image ? entry.id : "";
        previewRaw = entry && entry.image ? entry.raw : "";
        if (previewId === "") return;
        previewDelay.restart();
    }
    function startPreview(): void {
        if (preview.running || previewId === "") return;
        renderingPreviewId = previewId;
        preview.command = ["bash", "-c", "printf '%s\\n' \"$1\" | cliphist decode > \"$2\"", "cliphist-preview", previewRaw, previewPath];
        preview.running = true;
    }

    property Process listing: Process {
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    property Process copy: Process {}
    property Process deletion: Process { onExited: root.refresh() }
    property Timer previewDelay: Timer { interval: 80; onTriggered: root.startPreview() }
    property Process preview: Process {
        onExited: {
            if (root.renderingPreviewId === root.previewId)
                root.previewSource = "file://" + root.previewPath + "?id=" + root.previewId + "&t=" + Date.now();
            else
                root.startPreview();
        }
    }
}
