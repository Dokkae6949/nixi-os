import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."
import "components"
import "views"

ShellRoot {
    Component.onCompleted: Bootstrap.start()

    // Separate from the pill: privileged prompts must remain visible and own
    // keyboard focus until the PAM conversation succeeds or is cancelled.
    AuthenticationModal {}
    LockScreen {}

    IpcHandler {
        target: "nixi"

        function toggle(): bool {
            return ActionRegistry.run("surface.toggle");
        }
        function reveal(): bool {
            return ActionRegistry.run("surface.reveal");
        }
        function conceal(): bool {
            return ActionRegistry.run("surface.conceal");
        }
        function close(): bool {
            return ActionRegistry.run("surface.close");
        }
        function setEnabled(enabled: bool): bool {
            return ActionRegistry.run("surface.enabled.set", enabled);
        }
        function open(name: string): bool {
            return ActionRegistry.run("open." + name);
        }
        function action(id: string, argument: string): bool {
            return ActionRegistry.run(id, argument);
        }
        function setPowerProfile(profile: string): bool {
            return ActionRegistry.run("power.profile.set", profile);
        }
        function cyclePowerProfile(): bool {
            return ActionRegistry.run("power.profile.cycle");
        }
        function reportBluetoothKey(): bool {
            return ActionRegistry.run("hardware.bluetooth-key");
        }
        function lock(): bool {
            return ActionRegistry.run("session.lock");
        }
    }

    PanelWindow {
        id: pillWindow
        visible: SurfaceController.shown || surface.opacity > 0
        color: "transparent"
        exclusiveZone: 0
        // Keep the layer-shell geometry stable. Resizing the actual window on
        // every animation frame makes the compositor part of the animation.
        implicitWidth: Theme.windowWidth
        implicitHeight: Theme.windowHeight
        mask: Region {
            item: surface
        }

        anchors {
            top: true
        }
        margins {
            top: Settings.topMargin
        }
        WlrLayershell.keyboardFocus: SurfaceController.needsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Shortcut {
            enabled: SurfaceController.needsKeyboard && SurfaceController.pageOpen
            sequence: "Escape"
            context: Qt.WindowShortcut
            onActivated: SurfaceController.close()
        }

        AnimatedSurface {
            id: surface
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            targetWidth: SurfaceLayout.width(SurfaceController.content, homeView.implicitWidth, notificationPopup.implicitWidth, batteryView.implicitWidth)
            targetHeight: SurfaceLayout.height(SurfaceController.content, notificationPopup.implicitHeight, batteryView.implicitHeight, mediaView.implicitHeight)
            targetRadius: SurfaceLayout.radius(SurfaceController.content)
            targetPadding: SurfaceLayout.padding(SurfaceController.content)
            opacity: SurfaceController.shown ? 1 : 0
            scale: SurfaceController.shown ? 1 : 0.86
            enabled: SurfaceController.shown

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pillVisibility
                    easing.type: SurfaceController.shown ? Motion.easing : Easing.InCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Motion.pillVisibility
                    easing.type: SurfaceController.shown ? Motion.easing : Easing.InCubic
                }
            }

            SurfaceContent {
                contentId: SurfaceController.HomeContent
                contentPadding: surface.contentPadding
                HomeView {
                    id: homeView
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.StatusOsdContent
                contentPadding: surface.contentPadding
                StatusOsdView {
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.NotificationPopupContent
                contentPadding: surface.contentPadding
                NotificationPopupView {
                    id: notificationPopup
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.NotificationsContent
                NotificationsView {
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.BatteryContent
                BatteryView {
                    id: batteryView
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.systemMonitorContent
                PerformanceView {
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.clipboardContent
                contentPadding: surface.contentPadding
                ClipboardView {
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.LauncherContent
                contentPadding: surface.contentPadding
                LauncherView {
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.mediaContent
                MediaView {
                    id: mediaView
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.wifiContent
                contentPadding: surface.contentPadding
                WifiView {
                    anchors.fill: parent
                }
            }
            SurfaceContent {
                contentId: SurfaceController.bluetoothContent
                contentPadding: surface.contentPadding
                BluetoothView {
                    anchors.fill: parent
                }
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: ActionRegistry.run("surface.close")
            }
        }
    }
}
