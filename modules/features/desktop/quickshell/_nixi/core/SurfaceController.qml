pragma Singleton
import QtQuick
import ".."

// Owns only surface navigation. A page returns to the visibility state from
// which it was opened; an overlay interrupts without changing that state.
QtObject {
    enum Page {
        Home,
        Notifications,
        Battery,
        Launcher
    }
    enum Overlay {
        NoOverlay,
        NotificationPopup,
        StatusOsd
    }
    enum Content {
        HomeContent,
        NotificationsContent,
        BatteryContent,
        LauncherContent,
        NotificationPopupContent,
        StatusOsdContent
    }
    readonly property int systemMonitorPage: 4
    readonly property int systemMonitorContent: 6
    readonly property int clipboardPage: 5
    readonly property int clipboardContent: 7
    readonly property int mediaPage: 6
    readonly property int mediaContent: 8
    readonly property int wifiPage: 7
    readonly property int wifiContent: 9
    readonly property int bluetoothPage: 8
    readonly property int bluetoothContent: 10

    property bool userEnabled: true
    property bool homeVisible: true
    property bool returnHomeVisible: true
    property bool overviewVisible: false
    property int page: SurfaceController.Home
    property int overlay: SurfaceController.NoOverlay

    readonly property bool pageOpen: page !== SurfaceController.Home
    readonly property bool overlayOpen: overlay !== SurfaceController.NoOverlay
    readonly property bool requestedVisible: overlayOpen || overviewVisible || pageOpen || homeVisible
    readonly property bool shown: (userEnabled || overviewVisible) && requestedVisible
    readonly property int content: {
        if (overlay === SurfaceController.NotificationPopup)
            return SurfaceController.NotificationPopupContent;
        if (overlay === SurfaceController.StatusOsd)
            return SurfaceController.StatusOsdContent;
        if (overviewVisible)
            return SurfaceController.HomeContent;
        switch (page) {
        case SurfaceController.Notifications:
            return SurfaceController.NotificationsContent;
        case SurfaceController.Battery:
            return SurfaceController.BatteryContent;
        case systemMonitorPage:
            return systemMonitorContent;
        case clipboardPage:
            return clipboardContent;
        case mediaPage:
            return mediaContent;
        case wifiPage:
            return wifiContent;
        case bluetoothPage:
            return bluetoothContent;
        case SurfaceController.Launcher:
            return SurfaceController.LauncherContent;
        default:
            return SurfaceController.HomeContent;
        }
    }
    readonly property bool needsKeyboard: shown && (content === SurfaceController.LauncherContent || content === clipboardContent || content === wifiContent || content === bluetoothContent)

    function isPage(value: int): bool {
        return value >= SurfaceController.Home && value <= bluetoothPage;
    }

    function open(target: int): void {
        if (!isPage(target))
            return;
        clearOverlay();
        if (target === SurfaceController.Home) {
            showHome();
            return;
        }
        if (page === target) {
            close();
            return;
        }
        if (!pageOpen)
            returnHomeVisible = homeVisible;
        page = target;
    }

    function close(): void {
        if (overlayOpen) {
            clearOverlay();
            return;
        }
        if (!pageOpen)
            return;
        page = SurfaceController.Home;
        homeVisible = returnHomeVisible;
    }

    function showHome(): void {
        clearOverlay();
        page = SurfaceController.Home;
        homeVisible = true;
        returnHomeVisible = true;
    }

    function hide(): void {
        clearOverlay();
        page = SurfaceController.Home;
        homeVisible = false;
        returnHomeVisible = false;
    }

    function toggle(): void {
        if (pageOpen)
            close();
        else if (homeVisible)
            hide();
        else
            showHome();
    }

    function setEnabled(enabled: bool): void {
        userEnabled = enabled;
    }
    function setOverviewVisible(visible: bool): void {
        overviewVisible = visible;
    }

    function showOverlay(target: int): void {
        if (target === SurfaceController.NotificationPopup || target === SurfaceController.StatusOsd)
            overlay = target;
    }

    function clearOverlay(expected): void {
        const target = expected === undefined ? SurfaceController.NoOverlay : expected;
        if (overlayOpen && (target === SurfaceController.NoOverlay || overlay === target))
            overlay = SurfaceController.NoOverlay;
    }
}
