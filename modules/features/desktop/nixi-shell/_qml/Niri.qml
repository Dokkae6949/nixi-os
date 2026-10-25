pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Workspaces and the focused window title from Niri's event stream.
Singleton {
    id: root

    property var workspaces: []
    property var windows: ({})
    property var focusedId: null
    readonly property string title: focusedId !== null && windows[focusedId] ? windows[focusedId].title || "" : ""

    function focusWorkspace(idx: int): void {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }

    function setWindows(list: var): void {
        const map = {};
        for (const w of list) {
            map[w.id] = w;
            if (w.is_focused)
                focusedId = w.id;
        }
        windows = map;
    }

    function handle(line: string): void {
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (ev.WorkspacesChanged) {
            workspaces = ev.WorkspacesChanged.workspaces.sort((a, b) => a.idx - b.idx);
        } else if (ev.WorkspaceActivated) {
            const { id, focused } = ev.WorkspaceActivated;
            const output = workspaces.find(w => w.id === id)?.output;
            workspaces = workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === output ? w.id === id : w.is_active,
                is_focused: focused ? w.id === id : w.is_focused
            }));
        } else if (ev.WorkspaceActiveWindowChanged) {
            const { workspace_id, active_window_id } = ev.WorkspaceActiveWindowChanged;
            workspaces = workspaces.map(w => w.id === workspace_id ? Object.assign({}, w, { active_window_id }) : w);
        } else if (ev.WindowsChanged) {
            setWindows(ev.WindowsChanged.windows);
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            const map = Object.assign({}, windows);
            map[w.id] = w;
            windows = map;
            if (w.is_focused)
                focusedId = w.id;
        } else if (ev.WindowClosed) {
            const map = Object.assign({}, windows);
            delete map[ev.WindowClosed.id];
            windows = map;
        } else if (ev.WindowFocusChanged) {
            focusedId = ev.WindowFocusChanged.id;
        }
    }

    Socket {
        path: Quickshell.env("NIRI_SOCKET")
        connected: path !== ""
        onConnectionStateChanged: {
            if (connected) {
                write("\"EventStream\"\n");
                flush();
            }
        }
        parser: SplitParser {
            onRead: line => root.handle(line)
        }
    }
}
