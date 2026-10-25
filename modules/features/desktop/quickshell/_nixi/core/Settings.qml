pragma Singleton
import QtQuick
import ".."

QtObject {
    property int topMargin: 10
    property int osdTimeout: 1600
    property int notificationMinTimeout: 3500
    property int notificationMaxTimeout: 6000
    property int notificationCriticalTimeout: 8000
    property real notificationVolume: 0.55
    property bool criticalNotificationsBypassDnd: true
    property string defaultCriticalNotificationSound: "short-notice"
    property int lowBatteryWarningPercent: 15
    property int lowBatteryRearmPercent: 20
}
