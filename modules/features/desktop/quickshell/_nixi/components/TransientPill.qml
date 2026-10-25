import QtQuick
import ".."

// Animated host for short-lived content on non-morphing surfaces.
BaseSurface {
    id: root
    property bool shown: false
    default property alias content: contentItem.data

    visible: opacity > 0
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.94
    radius: Theme.radiusPill

    Item {
        id: contentItem
        anchors.fill: parent
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.fast
            easing.type: Motion.easing
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Motion.fast
            easing.type: Motion.easing
        }
    }
}
