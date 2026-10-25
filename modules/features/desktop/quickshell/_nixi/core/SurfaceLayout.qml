pragma Singleton
import QtQuick
import ".."

// Geometry for content identities. The window and navigation controller do
// not need to know individual view dimensions.
QtObject {
    function width(content: int, homeWidth: real, popupWidth: real, batteryWidth: real): real {
        switch (content) {
        case SurfaceController.NotificationsContent:
            return Theme.notificationCenterWidth;
        case SurfaceController.BatteryContent:
            return batteryWidth;
        case SurfaceController.systemMonitorContent:
            return Theme.performanceWidth;
        case SurfaceController.clipboardContent:
            return Theme.clipboardWidth;
        case SurfaceController.LauncherContent:
            return Theme.launcherWidth;
        case SurfaceController.mediaContent:
            return Theme.mediaWidth;
        case SurfaceController.wifiContent:
        case SurfaceController.bluetoothContent:
            return Theme.connectivityWidth;
        case SurfaceController.NotificationPopupContent:
            return popupWidth;
        case SurfaceController.StatusOsdContent:
            return Theme.osdWidth;
        default:
            return Math.max(Theme.homeMinWidth, homeWidth);
        }
    }

    function height(content: int, popupHeight: real, batteryHeight: real, mediaHeight: real): real {
        switch (content) {
        case SurfaceController.NotificationsContent:
            return Theme.notificationCenterHeight;
        case SurfaceController.BatteryContent:
            return batteryHeight;
        case SurfaceController.systemMonitorContent:
            return Theme.performanceHeight;
        case SurfaceController.clipboardContent:
            return Theme.clipboardHeight;
        case SurfaceController.LauncherContent:
            return Theme.launcherHeight;
        case SurfaceController.mediaContent:
            return Math.max(Theme.mediaMinHeight, mediaHeight);
        case SurfaceController.wifiContent:
        case SurfaceController.bluetoothContent:
            return Theme.connectivityHeight;
        case SurfaceController.NotificationPopupContent:
            return popupHeight;
        default:
            return Theme.homeHeight;
        }
    }

    function radius(content: int): real {
        switch (content) {
        case SurfaceController.NotificationsContent:
        case SurfaceController.BatteryContent:
        case SurfaceController.systemMonitorContent:
        case SurfaceController.clipboardContent:
        case SurfaceController.LauncherContent:
        case SurfaceController.mediaContent:
        case SurfaceController.wifiContent:
        case SurfaceController.bluetoothContent:
            return Theme.radiusPanel;
        default:
            return Theme.radiusPill;
        }
    }

    function padding(content: int): real {
        if (content === SurfaceController.LauncherContent || content === SurfaceController.clipboardContent || content === SurfaceController.wifiContent || content === SurfaceController.bluetoothContent)
            return Theme.spaceMd;
        return 0;
    }
}
