import QtQuick
import ".."

// Standard lifecycle and cross-fade behavior for content hosted by the surface.
Item {
    id: root
    required property int contentId
    property real contentPadding: 0
    default property alias content: contentItem.data

    anchors.fill: parent
    visible: opacity > 0
    enabled: SurfaceController.content === contentId
    opacity: enabled ? 1 : 0

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }

    Behavior on opacity {
        NumberAnimation { duration: Motion.fast; easing.type: Motion.easing }
    }
}
