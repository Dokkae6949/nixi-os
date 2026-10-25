import QtQuick
import Quickshell
import Quickshell.Wayland

WlSessionLock {
    locked: Session.locked

    WlSessionLockSurface {
        color: Theme.bg

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Column {
            anchors.centerIn: parent
            spacing: 18

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 56
                font.bold: true
            }

            Text {
                visible: Battery.present
                anchors.horizontalCenter: parent.horizontalCenter
                text: Battery.percent + "%" + (Battery.packs.length > 1 ? " (" + Battery.packs.map(d => Math.round(d.percentage * 100)).join("·") + ")" : "") + (Battery.onBattery ? "" : " · AC")
                color: Battery.onBattery && Battery.percent <= Battery.lowPercent ? Theme.red : Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 340
                height: 44
                color: Theme.bg
                border.width: Theme.borderWidth
                border.color: Session.failed ? Theme.red : password.activeFocus ? Theme.accent : Theme.border

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    enabled: Session.waiting
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
                    onAccepted: {
                        if (text === "")
                            return;
                        Session.submit(text);
                        text = "";
                    }
                    onEnabledChanged: if (enabled) forceActiveFocus()

                    Text {
                        visible: password.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: Session.waiting ? Session.user : "…"
                        color: Theme.muted
                        font: password.font
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Session.message
                color: Session.failed ? Theme.red : Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
