import QtQuick
import ".."
import "../components"

// Desktop policy adapter around the shared notification presentation.
Item {
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    NotificationCard {
        id: card
        anchors.fill: parent
        source: NotificationStore.current
        queueCount: NotificationStore.popupCount
        onDismissed: NotificationStore.dismissCurrent()
        onHoverChanged: hovered => PopupController.setNotificationHovered(hovered)
        onExpansionRequested: expanded => PopupController.setNotificationExpanded(expanded)
    }
}
