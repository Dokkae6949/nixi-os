import QtQuick

Item {
    id: root

    required property var list
    property bool active: true
    signal activated(int index)

    function move(delta: int): void {
        if (!active || list.count === 0)
            return;
        const start = list.currentIndex < 0 ? 0 : list.currentIndex;
        list.currentIndex = Math.max(0, Math.min(list.count - 1, start + delta));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    Shortcut {
        enabled: root.active
        sequence: "Ctrl+J"
        onActivated: root.move(1)
    }
    Shortcut {
        enabled: root.active
        sequence: "Ctrl+K"
        onActivated: root.move(-1)
    }
    Shortcut {
        enabled: root.active
        sequence: "Return"
        onActivated: if (root.list.currentIndex >= 0)
            root.activated(root.list.currentIndex)
    }
}
