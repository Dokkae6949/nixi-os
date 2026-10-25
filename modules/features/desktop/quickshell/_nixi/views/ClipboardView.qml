import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root
    property string query: ""
    property var filtered: CliphistService.entries.filter(entry => query === "" || entry.preview.toLowerCase().includes(query.toLowerCase()))

    function currentEntry() {
        return list.currentIndex >= 0 ? filtered[list.currentIndex] : null;
    }
    function select(index) {
        if (filtered.length === 0) {
            list.currentIndex = -1;
            return;
        }
        list.currentIndex = Math.max(0, Math.min(filtered.length - 1, index));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
        CliphistService.loadPreview(currentEntry());
    }
    function activate() {
        CliphistService.activate(currentEntry());
    }
    function remove() {
        CliphistService.remove(currentEntry());
    }

    onEnabledChanged: if (enabled) {
        query = "";
        CliphistService.refresh();
        Qt.callLater(searchField.focusInput);
    }
    onFilteredChanged: select(0)

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceSm

        TextEntry {
            id: searchField
            Layout.fillWidth: true
            implicitHeight: 44
            text: root.query
            placeholder: "Search clipboard…"
            onEdited: text => root.query = text
            onKeyPressed: event => {
                if (event.key === Qt.Key_Down || (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_J)) {
                    root.select(list.currentIndex + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_K)) {
                    root.select(list.currentIndex - 1);
                    event.accepted = true;
                } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_X) {
                    root.remove();
                    event.accepted = true;
                }
            }
            onAccepted: root.activate()
            onEscapePressed: SurfaceController.close()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceSm
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.filtered
                clip: true
                spacing: Theme.spaceXs
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 44
                    radius: Theme.radiusSm
                    color: ListView.isCurrentItem ? Theme.surfaceRaised : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spaceSm
                        spacing: Theme.spaceSm
                        Text {
                            text: modelData.image ? "▧" : "¶"
                            color: Theme.accent
                            font.pixelSize: Theme.fontBody
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.preview
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontBody
                        }
                    }
                    HoverHandler {
                        id: hover
                        onHoveredChanged: if (hovered)
                            root.select(index)
                    }
                    TapHandler {
                        onTapped: {
                            root.select(index);
                            root.activate();
                        }
                    }
                }
                WheelHandler {
                    target: list
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Theme.outline
            }

            Item {
                Layout.preferredWidth: 190
                Layout.fillHeight: true
                Image {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceSm
                    visible: root.currentEntry()?.image ?? false
                    source: visible ? CliphistService.previewSource : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Text {
                    anchors.fill: parent
                    anchors.margins: Theme.spaceSm
                    visible: !(root.currentEntry()?.image ?? false)
                    text: root.currentEntry()?.preview ?? "Clipboard is empty"
                    color: Theme.foregroundMuted
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Enter copy  ·  Ctrl+X remove  ·  Ctrl+J/K navigate"
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignRight
        }
    }
}
