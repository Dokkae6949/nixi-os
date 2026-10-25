import QtQuick
import ".."

BaseSurface {
    id: root
    property real targetWidth: Theme.homeMinWidth
    property real targetHeight: Theme.homeHeight
    property real targetRadius: Theme.radiusPill
    property real targetPadding: Theme.spaceMd
    property real contentPadding: targetPadding

    width: targetWidth
    height: targetHeight
    radius: targetRadius
    clip: true

    Behavior on width { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
    Behavior on height { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
    Behavior on radius { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
    Behavior on contentPadding { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
}
