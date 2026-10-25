import QtQuick
import Quickshell
import ".."

Item {
    id: root
    property string name
    property string fallbackName: ""
    property color color: Theme.foreground
    property int size: Theme.iconMedium

    readonly property var bundledIcons: ({
            "network-wireless-symbolic": "wifi.svg",
            "network-wireless-offline-symbolic": "wifi-off.svg",
            "network-wired-symbolic": "lan.svg",
            "bluetooth-symbolic": "bluetooth.svg",
            "audio-volume-high-symbolic": "volume.svg",
            "audio-volume-muted-symbolic": "volume-off.svg",
            "microphone-sensitivity-high-symbolic": "microphone.svg",
            "microphone-disabled-symbolic": "microphone-off.svg",
            "weather-clear-night-symbolic": "moon.svg",
            "preferences-system-symbolic": "settings.svg",
            "display-brightness-symbolic": "brightness.svg",
            "notification-symbolic": "notifications.svg",
            "notifications-active-symbolic": "notifications-active.svg",
            "notifications-off-symbolic": "notifications-off.svg",
            "notification-important-symbolic": "notification-important.svg",
            "nixi-authentication-symbolic": "authentication.svg",
            "system-search-symbolic": "search.svg",
            "view-more-symbolic": "more.svg",
            "view-restore-symbolic": "view.svg",
            "settings-symbolic": "settings.svg",
            "battery-symbolic": "battery.svg",
            "battery-low-symbolic": "battery-low.svg",
            "battery-good-symbolic": "battery-good.svg",
            "battery-caution-symbolic": "battery-low.svg",
            "speedometer-symbolic": "performance.svg",
            "window-close-symbolic": "close.svg",
            "system-lock-screen-symbolic": "lock.svg",
            "system-suspend-symbolic": "suspend.svg",
            "system-log-out-symbolic": "logout.svg",
            "system-reboot-symbolic": "reboot.svg",
            "system-shutdown-symbolic": "power.svg",
            "application-x-executable-symbolic": "application.svg",
            "nixi-power-saver-symbolic": "power-saver.svg",
            "nixi-power-balanced-symbolic": "power-balanced.svg",
            "nixi-power-performance-symbolic": "power-performance.svg",
            "edit-paste-symbolic": "clipboard.svg",
            "audio-x-generic-symbolic": "media.svg",
            "media-playback-start-symbolic": "media-play.svg",
            "media-playback-pause-symbolic": "media-pause.svg",
            "media-skip-backward-symbolic": "media-previous.svg",
            "media-skip-forward-symbolic": "media-next.svg",
            "media-playlist-shuffle-symbolic": "media-shuffle.svg",
            "starred-symbolic": "media-smart-shuffle.svg",
            "media-playlist-repeat-symbolic": "media-repeat.svg",
            "media-playlist-repeat-song-symbolic": "media-repeat-one.svg"
        })
    readonly property string bundledName: bundledIcons[name] || ""
    readonly property string themedPath: bundledName === "" ? Quickshell.iconPath(name) : ""
    readonly property string fallbackBundledName: bundledIcons[fallbackName] || ""

    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        visible: root.name !== ""
        source: !visible ? "" : root.bundledName !== "" ? Qt.resolvedUrl("../assets/icons/" + root.bundledName) : root.themedPath !== "" ? root.themedPath : root.fallbackBundledName !== "" ? Qt.resolvedUrl("../assets/icons/" + root.fallbackBundledName) : ""
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
