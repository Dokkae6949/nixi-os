pragma Singleton
import QtQuick
import ".."

QtObject {
    // Gruvbox Dark (medium contrast)
    readonly property color background: "#282828"
    readonly property color surface: "#3c3836"
    readonly property color surfaceRaised: "#504945"
    readonly property color foreground: "#ebdbb2"
    readonly property color foregroundMuted: "#a89984"
    readonly property color accent: "#83a598"
    readonly property color accentForeground: "#282828"
    readonly property color positive: "#b8bb26"
    readonly property color warning: "#fabd2f"
    readonly property color critical: "#fb4934"
    readonly property color outline: "#665c54"

    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 18
    readonly property int spaceXl: 24

    readonly property int radiusSm: 8
    readonly property int radiusPanel: 14
    readonly property int radiusPill: 24

    readonly property int fontSmall: 11
    readonly property int fontBody: 13
    readonly property int fontTitle: 18
    readonly property int fontWeightMedium: Font.DemiBold

    readonly property int iconSmall: 16
    readonly property int iconMedium: 20
    readonly property int iconLarge: 24
    readonly property int controlSize: 38

    readonly property int homeMinWidth: 300
    readonly property int homeCenterGap: 28
    readonly property int homeHeight: 40
    readonly property int osdWidth: 280
    readonly property int notificationMinWidth: 320
    readonly property int notificationMaxWidth: 500
    readonly property int notificationMinHeight: 66
    readonly property int notificationMaxHeight: 110
    readonly property int notificationExpandedWidth: 560
    readonly property int notificationExpandedMaxHeight: 300
    readonly property int notificationCenterWidth: 480
    readonly property int notificationCenterHeight: 390
    readonly property int batteryViewWidth: 500
    readonly property int batteryViewOneHeight: 230
    readonly property int batteryViewTwoHeight: 330
    readonly property int performanceWidth: 520
    readonly property int performanceHeight: 285
    readonly property int clipboardWidth: 560
    readonly property int clipboardHeight: 380
    readonly property int launcherWidth: 520
    readonly property int launcherHeight: 360
    readonly property int mediaWidth: 540
    readonly property int mediaMinHeight: 210
    readonly property int connectivityWidth: 540
    readonly property int connectivityHeight: 520
    readonly property int windowWidth: 640
    readonly property int windowHeight: 560
}
