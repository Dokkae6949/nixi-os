pragma Singleton
import QtQuick
import Quickshell
import ".."

QtObject {
    property SystemClock clock: SystemClock { precision: SystemClock.Minutes }
    readonly property string time: Qt.formatTime(clock.date, "HH:mm")
    readonly property string date: Qt.formatDate(clock.date, "ddd, d MMM")
}
