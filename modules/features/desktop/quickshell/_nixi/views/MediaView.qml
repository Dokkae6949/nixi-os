import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root
    implicitHeight: mediaLoader.active && mediaLoader.item ? mediaLoader.item.implicitHeight : Theme.mediaMinHeight

    readonly property var player: MediaService.player
    readonly property bool hasPlayer: MediaService.available

    // MPRIS positions are intentionally pull-based. Only poll while this page is
    // visible and playback is moving, keeping the hidden shell idle.
    Timer {
        interval: 500
        repeat: true
        running: root.visible && root.hasPlayer && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    Loader {
        id: mediaLoader
        active: root.hasPlayer
        anchors.fill: parent
        sourceComponent: Component {
            RowLayout {
                implicitHeight: controls.implicitHeight + Theme.spaceLg * 2
                anchors.fill: parent
                anchors.margins: Theme.spaceLg
                spacing: Theme.spaceLg

                Rectangle {
                    Layout.preferredWidth: 184
                    Layout.fillHeight: true
                    radius: Theme.radiusPanel
                    color: Theme.surfaceRaised

                    Image {
                        id: coverArt
                        anchors.fill: parent
                        source: root.player.trackArtUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: false
                    }

                    Rectangle {
                        id: artworkMask
                        anchors.fill: parent
                        radius: Theme.radiusPanel
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: coverArt
                        maskEnabled: true
                        maskSource: artworkMask
                        visible: coverArt.status === Image.Ready
                    }

                    NixiIcon {
                        anchors.centerIn: parent
                        name: "audio-x-generic-symbolic"
                        fallbackName: "application-x-executable-symbolic"
                        size: 56
                        color: Theme.foregroundMuted
                        visible: coverArt.status !== Image.Ready
                    }
                }

                ColumnLayout {
                    id: controls
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spaceSm

                    Text {
                        Layout.fillWidth: true
                        text: root.player.trackTitle || "Unknown title"
                        color: Theme.foreground
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.player.trackArtist || root.player.identity || "Unknown artist"
                        color: Theme.foregroundMuted
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.preferredHeight: Theme.spaceXs
                    }

                    Rectangle {
                        id: progress
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: height / 2
                        color: Theme.surfaceRaised

                        readonly property real ratio: root.player.lengthSupported && root.player.length > 0 ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0

                        Rectangle {
                            width: parent.width * progress.ratio
                            height: parent.height
                            radius: parent.radius
                            color: Theme.accent
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.player.canSeek && root.player.positionSupported && root.player.lengthSupported
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onPressed: mouse => root.player.position = root.player.length * mouse.x / width
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: MediaService.formatTime(root.player.position)
                            color: Theme.foregroundMuted
                            font.pixelSize: Theme.fontSmall
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.player.lengthSupported ? MediaService.formatTime(root.player.length) : "—:—"
                            color: Theme.foregroundMuted
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.spaceXs

                        IconButton {
                            iconName: "media-playlist-shuffle-symbolic"
                            accessibleName: "Shuffle"
                            active: root.player.shuffleSupported && root.player.shuffle
                            opacity: root.player.shuffleSupported ? 1 : 0.35
                            enabled: root.player.shuffleSupported && root.player.canControl
                            onClicked: root.player.shuffle = !root.player.shuffle
                        }
                        IconButton {
                            iconName: "media-skip-backward-symbolic"
                            accessibleName: "Previous"
                            opacity: root.player.canGoPrevious ? 1 : 0.35
                            enabled: root.player.canGoPrevious
                            onClicked: root.player.previous()
                        }
                        IconButton {
                            implicitWidth: Theme.controlSize + 8
                            implicitHeight: Theme.controlSize + 8
                            active: true
                            iconName: root.player.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                            accessibleName: root.player.isPlaying ? "Pause" : "Play"
                            enabled: root.player.canTogglePlaying
                            onClicked: root.player.togglePlaying()
                        }
                        IconButton {
                            iconName: "media-skip-forward-symbolic"
                            accessibleName: "Next"
                            opacity: root.player.canGoNext ? 1 : 0.35
                            enabled: root.player.canGoNext
                            onClicked: root.player.next()
                        }
                        IconButton {
                            iconName: MediaService.loopTrack ? "media-playlist-repeat-song-symbolic" : "media-playlist-repeat-symbolic"
                            accessibleName: MediaService.loopTrack ? "Repeat track" : MediaService.loopActive ? "Repeat playlist" : "Loop off"
                            active: root.player.loopSupported && MediaService.loopActive
                            opacity: root.player.loopSupported ? 1 : 0.35
                            enabled: root.player.loopSupported && root.player.canControl
                            onClicked: MediaService.cycleLoop()
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        visible: !root.hasPlayer
        anchors.centerIn: parent
        spacing: Theme.spaceMd

        NixiIcon {
            Layout.alignment: Qt.AlignHCenter
            name: "audio-x-generic-symbolic"
            fallbackName: "application-x-executable-symbolic"
            size: 52
            color: Theme.foregroundMuted
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing playing"
            color: Theme.foreground
            font.pixelSize: Theme.fontTitle
            font.weight: Font.Bold
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Start a media player and it will appear here"
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontBody
        }
    }
}
