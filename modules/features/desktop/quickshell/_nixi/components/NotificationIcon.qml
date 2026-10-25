import QtQuick
import Quickshell
import ".."

Rectangle {
    id: root
    required property string imageSource
    property bool critical: false
    property real tileSize: 40
    property real imageSize: tileSize * 0.68
    readonly property bool directImage: imageSource.indexOf("/") >= 0
                                        || imageSource.indexOf("image:") === 0

    implicitWidth: tileSize
    implicitHeight: tileSize
    radius: Math.round(tileSize * 0.28)
    color: Theme.surfaceRaised

    Image {
        id: notificationImage
        anchors.centerIn: parent
        width: parent.imageSize
        height: parent.imageSize
        visible: root.imageSource !== "" && root.directImage
        source: !visible ? ""
              : root.imageSource
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    NixiIcon {
        anchors.centerIn: parent
        visible: !notificationImage.visible
        name: root.imageSource !== ""
              ? root.imageSource
              : root.critical ? "notification-important-symbolic"
                              : "notification-symbolic"
        fallbackName: root.critical ? "notification-important-symbolic"
                                    : "notification-symbolic"
        size: root.imageSize
    }
}
