import QtQuick
import Quickshell
import Quickshell.Wayland

// The lock screen, one surface per output; the password field only on the
// first. Shares its look with the greeter through LockFrame.
WlSessionLock {
    locked: Session.locked
    onSecureChanged: Session.secure = secure

    WlSessionLockSurface {
        id: surface
        color: Theme.bgHard

        LockFrame {
            anchors.fill: parent
            primary: surface.screen === Quickshell.screens[0]
            opacity: 0
            Component.onCompleted: opacity = 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                spacing: 12

                AuthField {
                    id: password
                    placeholder: "Password for " + Session.user
                    busy: !Session.waiting
                    failed: Session.failed
                    onSubmitted: text => {
                        Session.submit(text);
                        password.text = "";
                    }
                    onTextChanged: if (text !== "") Session.failed = false

                    Connections {
                        target: Session
                        function onFailuresChanged(): void {
                            password.shake();
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
}
