pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import ".."

QtObject {
    id: root

    signal popupRequested
    signal popupSuppressed
    signal dndFeedbackRequested(enabled: bool)

    property alias doNotDisturb: persistedState.doNotDisturb
    property bool serverAvailable: true
    property int nextHistoryKey: 0
    property var history: []
    readonly property var notifications: server.trackedNotifications.values
    readonly property var popupNotifications: notifications.filter(function (notification) {
        return popupEligible(notification) && NotificationPolicy.allows(NotificationPolicy.channel(notification), NotificationPolicy.desktopContext) && (!doNotDisturb || (Settings.criticalNotificationsBypassDnd && notification.urgency === NotificationUrgency.Critical));
    }).sort(function (left, right) {
        const leftCritical = left.urgency === NotificationUrgency.Critical ? 1 : 0;
        const rightCritical = right.urgency === NotificationUrgency.Critical ? 1 : 0;
        return rightCritical - leftCritical;
    })
    readonly property int popupCount: popupNotifications.length
    readonly property var current: popupCount > 0 ? popupNotifications[0] : null
    readonly property int historyCount: history.length
    readonly property int unreadCount: history.filter(record => record.state === "new").length
    readonly property var centerNotifications: history.slice().sort(function (left, right) {
        const leftCritical = left.urgency === NotificationUrgency.Critical ? 1 : 0;
        const rightCritical = right.urgency === NotificationUrgency.Critical ? 1 : 0;
        return leftCritical !== rightCritical ? rightCritical - leftCritical : right.receivedAt - left.receivedAt;
    })
    readonly property int currentTimeout: {
        if (current === null)
            return Settings.notificationMinTimeout;
        if (current.urgency === NotificationUrgency.Critical)
            return Settings.notificationCriticalTimeout;

        const contentLength = current.summary.length + current.body.length;
        const readingFactor = Math.min(1, contentLength / 200);
        return Math.round(Settings.notificationMinTimeout + readingFactor * (Settings.notificationMaxTimeout - Settings.notificationMinTimeout));
    }

    function toggleDoNotDisturb(): void {
        setDoNotDisturb(!doNotDisturb);
    }

    function setDoNotDisturb(enabled: bool): void {
        if (doNotDisturb === enabled)
            return;
        doNotDisturb = enabled;
        dndFeedbackRequested(enabled);
    }

    function dismissCurrent(): void {
        if (current === null)
            return;
        const notification = current;
        removeFromHistory(notification);
        notification.tracked = false;
    }

    function expireCurrent(): void {
        if (current === null)
            return;
        const notification = current;
        markSeen(notification);
        notification.expire();
    }

    function markSeen(notification: var): void {
        history = history.map(function (item) {
            if (item.source !== notification)
                return item;
            return {
                key: item.key,
                source: null,
                appName: item.appName,
                summary: item.summary,
                body: item.body,
                image: item.image,
                urgency: item.urgency,
                receivedAt: item.receivedAt,
                state: "seen",
                popupEligible: false
            };
        });
    }

    function popupEligible(notification: var): bool {
        const record = history.find(item => item.source === notification);
        return record !== undefined && record.popupEligible === true;
    }

    function suppressPopup(notification: var): void {
        history = history.map(item => item.source === notification ? Object.assign({}, item, {
                popupEligible: false,
                state: "new"
            }) : item);
        popupSuppressed();
    }

    function removeFromHistory(notification: var): void {
        history = history.filter(item => item.source !== notification);
    }

    function dismissRecord(record: var): void {
        history = history.filter(item => item.key !== record.key);
        if (record.source !== null)
            record.source.tracked = false;
    }

    function clearHistory(): void {
        const records = history;
        history = [];
        for (const record of records) {
            if (record.source !== null)
                record.source.tracked = false;
        }
    }

    function markAllActiveSeen(): void {
        const activeNotifications = notifications.slice();
        for (const notification of activeNotifications) {
            markSeen(notification);
            notification.expire();
        }
    }

    function handleClosed(notification: var): void {
        // Notifications closed by their sender are retained as seen unless the
        // user explicitly removed them first.
        markSeen(notification);
    }

    function receive(notification: var): void {
        const image = notification.image !== "" ? notification.image : notification.appIcon;
        history = history.concat([
            {
                key: ++nextHistoryKey,
                source: notification,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                image: image,
                urgency: notification.urgency,
                receivedAt: Date.now(),
                state: !LockService.locked && (SurfaceController.page === SurfaceController.Home || notification.urgency === NotificationUrgency.Critical) ? "presented" : "new",
                popupEligible: !LockService.locked && (SurfaceController.page === SurfaceController.Home || notification.urgency === NotificationUrgency.Critical)
            }
        ]);
        notification.closed.connect(function () {
            root.handleClosed(notification);
        });
        notification.tracked = true;
        // DND is always acoustically silent, including for critical popups.
        const channel = NotificationPolicy.channel(notification);
        if (NotificationPolicy.allows(channel, LockService.locked ? NotificationPolicy.lockContext : NotificationPolicy.desktopContext))
            NotificationSound.play(notification.urgency, doNotDisturb);
    }

    function checkServer(): void {
        ownershipCheck.exec(["bash", "-c", "owner=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus GetNameOwner s org.freedesktop.Notifications 2>/dev/null | cut -d '\"' -f 2); [ -n \"$owner\" ] || exit 1; owner_pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID s \"$owner\" 2>/dev/null | awk '{print $2}'); [ \"$owner_pid\" = \"$1\" ]", "notification-owner", String(Quickshell.processId)]);
    }

    onDoNotDisturbChanged: {
        if (doNotDisturb && current === null)
            popupSuppressed();
        else if (current !== null)
            popupRequested();
    }

    property PersistentProperties persisted: PersistentProperties {
        id: persistedState
        reloadableId: "notificationState"
        property bool doNotDisturb: false
    }

    property NotificationServer server: NotificationServer {
        bodySupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true
    }

    property Connections serverSignals: Connections {
        target: server
        function onNotification(notification): void {
            root.receive(notification);
        }
    }

    property Connections notificationModelSignals: Connections {
        target: server.trackedNotifications
        function onObjectInsertedPost(): void {
            // The reactive values are settled before popup presentation.
            if (root.current !== null)
                root.popupRequested();
        }
        function onObjectRemovedPost(): void {
            if (root.popupCount === 0)
                root.popupSuppressed();
        }
    }

    property Connections lockSignals: Connections {
        target: LockService
        function onLockedChanged(): void {
            if (LockService.locked)
                root.popupSuppressed();
        }
    }

    property Process ownershipCheck: Process {
        function onExited(exitCode, exitStatus): void {
            root.serverAvailable = exitCode === 0;
        }
    }

    property Timer ownershipTimer: Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.checkServer()
    }
}
