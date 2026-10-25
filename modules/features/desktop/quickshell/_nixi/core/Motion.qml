pragma Singleton
import QtQuick
import ".."

QtObject {
    property bool enabled: true
    property real speedScale: 1.0

    readonly property int pillVisibility: enabled ? Math.round(80 / Math.max(0.1, speedScale)) : 0
    readonly property int fast: enabled ? Math.round(120 / Math.max(0.1, speedScale)) : 0
    readonly property int normal: enabled ? Math.round(220 / Math.max(0.1, speedScale)) : 0
    readonly property int slow: enabled ? Math.round(320 / Math.max(0.1, speedScale)) : 0
    readonly property int easing: Easing.OutCubic
}
