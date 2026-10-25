import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".."
import "../components"

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceLg
        spacing: Theme.spaceMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            NixiIcon {
                name: NotificationStore.historyCount > 0
                      ? "notifications-active-symbolic"
                      : "notification-symbolic"
                size: Theme.iconLarge
            }

            Text {
                text: "Notifications"
                color: Theme.foreground
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.fontWeightMedium
            }

            Badge {
                visible: NotificationStore.historyCount > 0
                text: NotificationStore.historyCount
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: NotificationStore.historyCount > 0
                implicitWidth: clearLabel.implicitWidth + Theme.spaceMd * 2
                implicitHeight: 30
                radius: height / 2
                color: clearHover.hovered ? Theme.surfaceRaised : "transparent"

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontSmall
                }

                HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: NotificationStore.clearHistory() }
            }

            IconButton {
                iconName: NotificationStore.doNotDisturb
                          ? "notifications-off-symbolic"
                          : "notification-symbolic"
                active: NotificationStore.doNotDisturb
                accessibleName: "Toggle Do Not Disturb"
                onClicked: NotificationStore.toggleDoNotDisturb()
            }
        }

        Rectangle {
            visible: NotificationStore.doNotDisturb
            Layout.fillWidth: true
            implicitHeight: 34
            radius: Theme.radiusSm
            color: Theme.surfaceRaised

            Row {
                anchors.centerIn: parent
                spacing: Theme.spaceSm
                NixiIcon { name: "notifications-off-symbolic"; size: Theme.iconSmall }
                Text {
                    text: Settings.criticalNotificationsBypassDnd
                          ? "Do Not Disturb is on — only important alerts can interrupt"
                          : "Do Not Disturb is on — new notifications stay here silently"
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontSmall
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                visible: NotificationStore.historyCount === 0
                text: "You're all caught up"
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontBody
            }

            ListView {
                id: notificationList
                anchors.fill: parent
                visible: NotificationStore.historyCount > 0
                clip: true
                spacing: Theme.spaceSm
                boundsBehavior: Flickable.StopAtBounds
                model: NotificationStore.centerNotifications

                delegate: Rectangle {
                    id: notificationDelegate
                    required property var modelData
                    property bool expanded: false
                    width: notificationList.width - (scrollTrack.visible ? Theme.spaceSm : 0)
                    height: expanded
                            ? Math.min(250, Math.max(84, centerContent.implicitHeight + Theme.spaceMd * 2))
                            : modelData.body === "" ? 68 : 84
                    radius: Theme.radiusPanel
                    color: Theme.surfaceRaised
                    border.width: modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                    border.color: Theme.critical

                    Behavior on height { NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: parent.expanded = !parent.expanded }

                    RowLayout {
                        id: centerContent
                        anchors.fill: parent
                        anchors.margins: Theme.spaceMd
                        spacing: Theme.spaceMd

                        NotificationIcon {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            imageSource: modelData.image
                            critical: modelData.urgency === NotificationUrgency.Critical
                            tileSize: 38
                            color: Theme.surface
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary !== "" ? modelData.summary : modelData.appName
                                    color: Theme.foreground
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Theme.fontWeightMedium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.urgency === NotificationUrgency.Critical ? "Important"
                                          : modelData.state === "seen" ? "Seen" : "New"
                                    color: modelData.urgency === NotificationUrgency.Critical
                                           ? Theme.critical : Theme.foregroundMuted
                                    font.pixelSize: Theme.fontSmall
                                }
                                Text {
                                    text: Qt.formatTime(new Date(modelData.receivedAt), "HH:mm")
                                    color: Theme.foregroundMuted
                                    font.pixelSize: Theme.fontSmall
                                }
                            }

                            Text {
                                visible: modelData.body !== ""
                                Layout.fillWidth: true
                                text: modelData.body
                                textFormat: Text.PlainText
                                color: Theme.foregroundMuted
                                font.pixelSize: Theme.fontSmall
                                maximumLineCount: notificationDelegate.expanded ? 12 : 2
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                            }
                        }

                        DismissButton {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            buttonSize: 28
                            hoverColor: Theme.surface
                            onClicked: NotificationStore.dismissRecord(modelData)
                        }
                    }
                }
            }

            Rectangle {
                id: scrollTrack
                visible: notificationList.contentHeight > notificationList.height
                anchors.right: parent.right
                anchors.top: parent.top
                width: 3
                height: parent.height
                radius: width / 2
                color: Theme.surfaceRaised

                Rectangle {
                    width: parent.width
                    height: Math.max(24, notificationList.height * notificationList.height
                                     / notificationList.contentHeight)
                    y: notificationList.contentY
                       / Math.max(1, notificationList.contentHeight - notificationList.height)
                       * (scrollTrack.height - height)
                    radius: width / 2
                    color: Theme.foregroundMuted
                }
            }
        }
    }
}
