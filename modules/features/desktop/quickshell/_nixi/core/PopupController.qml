pragma Singleton
import QtQuick
import ".."

// Owns ephemeral notification and status OSD presentation, including timers.
// SurfaceController only stores which overlay currently interrupts the page.
QtObject {
    id: root

    property string osdIcon: ""
    property string osdLabel: ""
    property real osdValue: -1
    property string osdKind: "level"
    property string osdText: ""
    property bool notificationHovered: false
    property bool notificationExpanded: false
    property int notificationRemaining: 0
    property double notificationDeadline: 0

    function showNotification(): void {
        if (SurfaceController.page === SurfaceController.Notifications) {
            NotificationStore.markAllActiveSeen();
            return;
        }
        if (NotificationStore.popupCount === 0)
            return;
        const alreadyVisible = SurfaceController.overlay === SurfaceController.NotificationPopup;
        osdTimer.stop();
        SurfaceController.showOverlay(SurfaceController.NotificationPopup);
        if (!alreadyVisible)
            resetNotificationTimer();
    }

    function resetNotificationTimer(): void {
        notificationRemaining = NotificationStore.currentTimeout;
        notificationTimer.interval = notificationRemaining;
        notificationDeadline = Date.now() + notificationRemaining;
        if (notificationHovered || notificationExpanded)
            notificationTimer.stop();
        else
            notificationTimer.restart();
    }

    function setNotificationHovered(hovered: bool): void {
        if (notificationHovered === hovered)
            return;
        notificationHovered = hovered;
        updateNotificationTimer(hovered || notificationExpanded);
    }

    function setNotificationExpanded(expanded: bool): void {
        notificationExpanded = expanded;
        updateNotificationTimer(expanded || notificationHovered);
    }

    function updateNotificationTimer(paused: bool): void {
        if (paused) {
            notificationRemaining = Math.max(1, Math.round(notificationDeadline - Date.now()));
            notificationTimer.stop();
        } else if (SurfaceController.overlay === SurfaceController.NotificationPopup && NotificationStore.current !== null) {
            notificationTimer.interval = notificationRemaining;
            notificationDeadline = Date.now() + notificationRemaining;
            notificationTimer.restart();
        }
    }

    function showOsd(icon: string, label: string, value: real, kind: string): void {
        notificationTimer.stop();
        osdIcon = icon;
        osdLabel = label;
        osdValue = value;
        osdKind = kind || "level";
        osdText = "";
        SurfaceController.showOverlay(SurfaceController.StatusOsd);
        osdTimer.restart();
    }

    function showMessage(icon: string, label: string, text: string): void {
        notificationTimer.stop();
        osdIcon = icon;
        osdLabel = label;
        osdValue = -1;
        osdKind = "message";
        osdText = text;
        SurfaceController.showOverlay(SurfaceController.StatusOsd);
        osdTimer.restart();
    }

    function dismissOverlay(): void {
        if (SurfaceController.overlay === SurfaceController.NotificationPopup && NotificationStore.current !== null)
            NotificationStore.expireCurrent();
        SurfaceController.clearOverlay();
    }

    property Timer osdTimer: Timer {
        interval: Settings.osdTimeout
        onTriggered: {
            if (NotificationStore.popupCount > 0)
                root.showNotification();
            else
                SurfaceController.clearOverlay(SurfaceController.StatusOsd);
        }
    }

    property Timer notificationTimer: Timer {
        onTriggered: NotificationStore.expireCurrent()
    }

    property Connections surfaceSignals: Connections {
        target: SurfaceController
        function onPageChanged(): void {
            if (SurfaceController.page !== SurfaceController.Home && SurfaceController.overlay === SurfaceController.NotificationPopup && NotificationStore.current !== null && NotificationStore.current.urgency !== 2)
                NotificationStore.suppressPopup(NotificationStore.current);
        }
        function onOverlayChanged(): void {
            if (SurfaceController.overlay !== SurfaceController.StatusOsd)
                root.osdTimer.stop();
            if (SurfaceController.overlay !== SurfaceController.NotificationPopup) {
                root.notificationTimer.stop();
                root.notificationExpanded = false;
            }
        }
    }

    property Connections notificationSignals: Connections {
        target: NotificationStore
        function onPopupRequested(): void {
            root.showNotification();
        }
        function onPopupSuppressed(): void {
            SurfaceController.clearOverlay(SurfaceController.NotificationPopup);
        }
        function onDndFeedbackRequested(enabled): void {
            root.showOsd(enabled ? "notifications-off-symbolic" : "notification-symbolic", "Do Not Disturb", enabled ? 1 : 0, "status");
        }
        function onCurrentChanged(): void {
            root.notificationExpanded = false;
            if (SurfaceController.overlay === SurfaceController.NotificationPopup && NotificationStore.current !== null)
                root.resetNotificationTimer();
        }
    }
}
