import QtQuick
import QtQuick.Layouts
import ".."

// Presentation-only notification content. The caller owns selection, timeout,
// dismissal, and privacy policy through this small interface.
Item {
    id: root

    property var source: null
    property int queueCount: 0
    property bool dismissible: true
    property bool expandable: true
    property bool interactive: true
    property bool expanded: false
    property string displayedSummary: ""
    property string displayedBody: ""
    property string displayedImage: ""
    property bool displayedCritical: false

    signal dismissed
    signal hoverChanged(hovered: bool)
    signal expansionRequested(expanded: bool)

    function longestLine(value: string): string {
        const lines = value.split(/\r?\n/);
        let longest = "";
        for (const line of lines) {
            if (line.length > longest.length)
                longest = line;
        }
        return longest;
    }

    readonly property real chromeWidth: 42 + Theme.spaceMd * 2 + Theme.spaceLg * 2 + (dismissible ? 30 + Theme.spaceMd : 0) + (queueCount > 1 ? queueBadge.implicitWidth + Theme.spaceMd : 0)
    readonly property real collapsedMessageWidth: Math.max(summaryMetrics.advanceWidth, bodyMetrics.advanceWidth)
    readonly property real desiredTextHeight: Math.max(42, messageColumn.implicitHeight)
    implicitWidth: expanded ? Theme.notificationExpandedWidth : Math.min(Theme.notificationMaxWidth, Math.max(Theme.notificationMinWidth, collapsedMessageWidth + chromeWidth))
    implicitHeight: Math.min(expanded ? Theme.notificationExpandedMaxHeight : Theme.notificationMaxHeight, Math.max(Theme.notificationMinHeight, desiredTextHeight + Theme.spaceMd * 2))
    clip: true

    onSourceChanged: {
        // Retain the last content while its host animates away.
        if (source === null)
            return;
        expanded = false;
        displayedSummary = source.summary || "";
        displayedBody = source.body || "";
        displayedImage = source.image || source.appIcon || "";
        displayedCritical = source.critical === true || source.urgency === 2;
        messageTransition.restart();
    }

    TextMetrics {
        id: summaryMetrics
        font: summaryText.font
        text: root.longestLine(root.displayedSummary)
    }
    TextMetrics {
        id: bodyMetrics
        font: bodyText.font
        text: root.longestLine(root.displayedBody)
    }

    HoverHandler {
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: root.hoverChanged(hovered)
    }
    TapHandler {
        enabled: root.interactive && root.expandable
        onTapped: {
            root.expanded = !root.expanded;
            root.expansionRequested(root.expanded);
        }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceLg
        anchors.rightMargin: Theme.spaceLg
        anchors.topMargin: Theme.spaceMd
        anchors.bottomMargin: Theme.spaceMd
        spacing: Theme.spaceMd
        transform: Translate {
            id: contentShift
        }

        NotificationIcon {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            imageSource: root.displayedImage
            critical: root.displayedCritical
            tileSize: 42
        }

        ColumnLayout {
            id: messageColumn
            Layout.fillWidth: true
            spacing: 3

            Text {
                id: summaryText
                Layout.fillWidth: true
                text: root.displayedSummary
                color: Theme.foreground
                font.pixelSize: Theme.fontBody + 1
                font.weight: Theme.fontWeightMedium
                elide: Text.ElideRight
                maximumLineCount: root.expanded ? 2 : 1
                wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
            }
            Text {
                id: bodyText
                Layout.fillWidth: true
                visible: text !== ""
                text: root.displayedBody
                textFormat: Text.PlainText
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontBody
                elide: Text.ElideRight
                maximumLineCount: root.expanded ? 10 : 3
                wrapMode: Text.Wrap
            }
        }

        Badge {
            id: queueBadge
            visible: root.queueCount > 1
            text: "+" + (root.queueCount - 1)
        }
        DismissButton {
            visible: root.dismissible
            Layout.preferredWidth: visible ? 30 : 0
            Layout.preferredHeight: 30
            onClicked: root.dismissed()
        }
    }

    ParallelAnimation {
        id: messageTransition
        NumberAnimation {
            target: content
            property: "opacity"
            from: 0
            to: 1
            duration: Motion.normal
            easing.type: Motion.easing
        }
        NumberAnimation {
            target: contentShift
            property: "x"
            from: 10
            to: 0
            duration: Motion.normal
            easing.type: Motion.easing
        }
    }
}
