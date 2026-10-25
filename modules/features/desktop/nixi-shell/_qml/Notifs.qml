pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. Entries are plain records in two ListModels: `history`
// (newest first, capped) and `popups` (what is currently on screen). `nid`
// links a record to its D-Bus notification, or is -1 for the shell's own
// notifications (battery warnings and the like).
Singleton {
    id: root

    property alias dnd: persist.dnd
    readonly property int count: history.count
    readonly property int maxHistory: 50
    readonly property int maxPopups: 4
    property int nextKey: 0

    property ListModel history: ListModel {}
    property ListModel popups: ListModel {}

    // Shell-internal notification. `tag` lets the poster replace or withdraw
    // its previous one.
    function post(summary: string, body: string, critical: bool, tag: string): void {
        withdraw(tag);
        add({ nid: -1, tag: tag, app: "nixi-shell", summary: summary, body: body, icon: "", critical: critical, timeout: critical ? 0 : 6000 });
    }

    function withdraw(tag: string): void {
        if (tag === "")
            return;
        removeWhere(history, r => r.tag === tag);
        removeWhere(popups, r => r.tag === tag);
    }

    function add(record: var): void {
        record.key = ++nextKey;
        record.time = Qt.formatTime(new Date(), "HH:mm");
        history.insert(0, record);
        while (history.count > maxHistory)
            dismissAt(history.count - 1);

        const visible = !Session.locked && (!dnd || record.critical);
        if (visible) {
            popups.insert(0, record);
            for (let i = popups.count - 1; i >= 0 && popups.count > maxPopups; --i) {
                if (!popups.get(i).critical)
                    popups.remove(i);
            }
        }
        if (!dnd)
            Quickshell.execDetached(["pw-play", "--volume", "0.55", Quickshell.shellPath(record.critical ? "assets/audio/critical-short-notice.ogg" : "assets/audio/notify.oga")]);
    }

    function removeWhere(model: ListModel, predicate: var): void {
        for (let i = model.count - 1; i >= 0; --i) {
            if (predicate(model.get(i)))
                model.remove(i);
        }
    }

    function source(nid: int): var {
        if (nid < 0)
            return null;
        for (const n of server.trackedNotifications.values) {
            if (n.id === nid)
                return n;
        }
        return null;
    }

    function dismissAt(index: int): void {
        const record = history.get(index);
        const key = record.key;
        const n = source(record.nid);
        history.remove(index);
        removeWhere(popups, r => r.key === key);
        if (n)
            n.dismiss();
    }

    function dismiss(key: int): void {
        for (let i = 0; i < history.count; ++i) {
            if (history.get(i).key === key)
                return dismissAt(i);
        }
        removeWhere(popups, r => r.key === key);
    }

    // Popup timed out: it stays in history.
    function hidePopup(key: int): void {
        removeWhere(popups, r => r.key === key);
    }

    function activate(key: int): void {
        let nid = -1;
        for (let i = 0; i < history.count; ++i) {
            if (history.get(i).key === key)
                nid = history.get(i).nid;
        }
        const n = source(nid);
        if (n) {
            const action = n.actions.find(a => a.identifier === "default") ?? (n.actions.length === 1 ? n.actions[0] : null);
            if (action)
                action.invoke();
        }
        dismiss(key);
    }

    function clearPopups(): void {
        popups.clear();
    }

    function clearAll(): void {
        popups.clear();
        while (history.count > 0)
            dismissAt(history.count - 1);
    }

    function toggleDnd(): void {
        dnd = !dnd;
        if (dnd)
            removeWhere(popups, r => !r.critical);
    }

    PersistentProperties {
        id: persist
        reloadableId: "nixiShellNotifs"
        property bool dnd: false
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const nid = n.id;
            // Replacements reuse the id; drop the old record first.
            root.removeWhere(root.history, r => r.nid === nid);
            root.removeWhere(root.popups, r => r.nid === nid);
            const critical = n.urgency === NotificationUrgency.Critical;
            root.add({
                nid: nid,
                tag: "",
                app: n.appName,
                summary: n.summary,
                body: n.body,
                icon: n.image !== "" ? n.image : (n.appIcon !== "" ? Quickshell.iconPath(n.appIcon, true) : ""),
                critical: critical,
                timeout: critical ? 0 : n.expireTimeout > 0 ? Math.max(n.expireTimeout, 3000) : 5000
            });
            n.closed.connect(() => root.removeWhere(root.popups, r => r.nid === nid));
        }
    }
}
