import QtQuick
import ".."

Item {
    id: root

    property int strength: 100
    property bool connected: true
    property color color: Theme.foreground
    property real inactiveOpacity: 0.2
    property int size: Theme.iconMedium

    readonly property string activeIcon: strength >= 67 ? "wifi.svg"
                                                : strength >= 34 ? "wifi-2.svg"
                                                                 : "wifi-1.svg"

    implicitWidth: size
    implicitHeight: size

    // A complete, faint symbol keeps the icon's silhouette stable. The
    // appropriate Material strength glyph is layered precisely over it.
    Image {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        source: Qt.resolvedUrl("../assets/icons/wifi.svg")
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        opacity: root.inactiveOpacity
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Image {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        source: Qt.resolvedUrl("../assets/icons/" + root.activeIcon)
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        opacity: root.connected ? 1 : 0
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true

        Behavior on opacity {
            NumberAnimation { duration: Motion.fast }
        }
    }
}

