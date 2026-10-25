import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"

Item {
    id: root
    property string query: ""
    property var results: buildResults(query, DesktopEntries.applications.values, ActionRegistry.entries)

    function buildResults(text, applications, commands) {
        const needle = text.trim().toLowerCase();
        const matches = value => needle.length === 0 || String(value).toLowerCase().includes(needle);
        const output = [];

        for (const command of commands) {
            const haystack = command.label + " " + command.group + " " + (command.keywords || "");
            if (command.id !== "open.launcher" && matches(haystack))
                output.push({
                    kind: "command",
                    title: command.label,
                    subtitle: command.group,
                    icon: command.icon,
                    command: command.id
                });
        }

        for (const application of applications) {
            const haystack = application.name + " " + (application.comment || "") + " " + (application.keywords || "");
            if (matches(haystack))
                output.push({
                    kind: "application",
                    title: application.name,
                    subtitle: "Application",
                    icon: application.icon,
                    application: application
                });
        }
        return output.slice(0, 40);
    }

    function activate(index) {
        if (index < 0 || index >= results.length)
            return;
        const entry = results[index];
        if (entry.kind === "application") {
            entry.application.execute();
            SurfaceController.close();
        } else {
            ActionRegistry.run(entry.command);
            if (entry.command.indexOf("open.") !== 0)
                SurfaceController.close();
        }
    }

    onEnabledChanged: {
        if (enabled) {
            query = "";
            resultList.currentIndex = 0;
            Qt.callLater(searchField.focusInput);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceSm

        TextEntry {
            id: searchField
            Layout.fillWidth: true
            text: root.query
            placeholder: "Type to search…"
            leadingIcon: "system-search-symbolic"
            onEdited: text => {
                root.query = text;
                resultList.currentIndex = root.results.length > 0 ? 0 : -1;
            }
            onKeyPressed: event => {
                if (event.key === Qt.Key_Down || (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_J)) {
                    resultList.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_K)) {
                    resultList.decrementCurrentIndex();
                    event.accepted = true;
                }
            }
            onAccepted: root.activate(resultList.currentIndex)
            onEscapePressed: SurfaceController.close()
        }

        ListView {
            id: resultList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spaceXs
            model: root.results
            onCountChanged: if (count > 0 && currentIndex < 0)
                currentIndex = 0

            delegate: Rectangle {
                id: result
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 48
                radius: Theme.radiusSm
                color: ListView.isCurrentItem || hover.hovered ? Theme.surfaceRaised : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceMd
                    anchors.rightMargin: Theme.spaceMd
                    spacing: Theme.spaceMd
                    NixiIcon {
                        name: result.modelData.icon || "application-x-executable-symbolic"
                        fallbackName: result.modelData.kind === "application" ? "application-x-executable-symbolic" : ""
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: result.modelData.title
                            color: Theme.foreground
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }
                        Text {
                            text: result.modelData.subtitle
                            color: Theme.foregroundMuted
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }
                HoverHandler {
                    id: hover
                    onHoveredChanged: if (hovered)
                        resultList.currentIndex = result.index
                }
                TapHandler {
                    onTapped: root.activate(result.index)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: resultList.count === 0
                text: "No matches"
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontBody
            }
        }
    }
}
