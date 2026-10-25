import QtQuick
import ".."

Item {
    id: root
    property int percent: 100
    property bool charging: false
    property real iconScale: 1
    readonly property int boundedPercent: Math.min(100, Math.max(0, percent))
    readonly property color fillColor: charging
                                        ? Theme.positive
                                        : boundedPercent <= 20
                                          ? Theme.critical
                                          : Theme.foreground

    implicitWidth: 36 * iconScale
    implicitHeight: 16 * iconScale

    Rectangle {
        id: body
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 28 * root.iconScale
        height: 14 * root.iconScale
        radius: 4 * root.iconScale
        color: "#5f6368"
        clip: true

        Item {
            id: fillClip
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.boundedPercent / 100
            clip: true

            Rectangle {
                width: body.width
                height: body.height
                radius: body.radius
                color: root.fillColor
            }
        }

        Text {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.boundedPercent
            color: Theme.background
            font.pixelSize: 11 * root.iconScale
            font.weight: Font.Bold
        }
    }

    Rectangle {
        visible: !root.charging
        anchors.left: body.right
        anchors.verticalCenter: parent.verticalCenter
        width: 3 * root.iconScale
        height: 6 * root.iconScale
        radius: root.iconScale
        color: "#5f6368"
    }

    Canvas {
        visible: root.charging
        width: 7 * root.iconScale
        height: 12 * root.iconScale
        anchors.left: body.right
        anchors.leftMargin: root.iconScale
        anchors.verticalCenter: parent.verticalCenter

        onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)
            context.fillStyle = root.fillColor
            context.beginPath()
            context.moveTo(width * 0.6, 0)
            context.lineTo(width * 0.07, height * 0.54)
            context.lineTo(width * 0.46, height * 0.54)
            context.lineTo(width * 0.31, height)
            context.lineTo(width * 0.93, height * 0.4)
            context.lineTo(width * 0.54, height * 0.4)
            context.closePath()
            context.fill()
        }
    }
}
