# Nixi

Nixi is a keyboard-first desktop shell for the Niri compositor, built with
Quickshell and Qt Quick. Its compact top surface morphs into notifications,
battery information, a launcher, and transient status displays.

## Run

```bash
nix develop
qs -p ./shell.qml
```

Or run the packaged shell with `nix run .`. When installed as the named
Quickshell configuration under `~/.config/quickshell/nixi`, use `-c nixi` for
IPC calls.

## Architecture

Navigation, ephemeral presentation, actions, and system integration have
separate owners:

```text
Niri / UPower / NetworkManager / BlueZ / PipeWire / Notifications / PolicyKit
                                  │
                         focused service objects
                                  │
                           ActionRegistry
                                  │
             SurfaceController ───┴─── PopupController
                      │                       │
                      └── AnimatedSurface + content views
```

### Surface state

`core/SurfaceController.qml` models three concepts:

1. **Home** is the resting pill and may be visible or hidden.
2. **Pages** are user-opened content. Opening one captures whether closing it
   should return to visible home or hidden.
3. **Overlays** are notification popups and status OSDs. They interrupt without
   changing the page beneath them.

`close()` removes the topmost concept: an overlay first, otherwise the open
page. A page opened from visible home returns home; one opened while hidden
returns to hidden. Niri overview visibility never rewrites that destination.

`core/PopupController.qml` owns notification timing, hover/expansion pauses,
and OSD payloads. `core/SurfaceLayout.qml` owns content geometry.

### Actions and services

`core/ActionRegistry.qml` is the mutation entry point shared by IPC, the
launcher, and buttons. Stable intent-based IDs avoid adding a new IPC method
for every feature. The launcher renders the same action catalog it executes.

Services are capability-sized. Clock, power, network, Bluetooth, audio,
brightness, session operations, notifications, and compositor integration each
have one owner. Audio, radio, and brightness feedback are separate from the
underlying state services. `core/Bootstrap.qml` starts long-lived integrations.

Repository layout:

```text
.
├── shell.qml          # root window and small IPC adapter
├── core/              # navigation, popup policy, actions, layout, settings
├── services/          # focused system and desktop integrations
├── components/        # reusable visual primitives
├── views/             # presentation-only surface content
├── assets/            # packaged icons and audio
└── flake.nix          # development environment and package
```

To add a page:

1. Add page and content identities to `SurfaceController`.
2. Add geometry to `SurfaceLayout` and design tokens to `Theme.qml`.
3. Host it through `SurfaceContent` in `shell.qml`.
4. Register an `open.*` action in `ActionRegistry`.

Views must not own subprocesses, hardware monitoring, or popup timers.

## IPC

The IPC surface is deliberately small:

```bash
qs -c nixi ipc call nixi toggle
qs -c nixi ipc call nixi reveal
qs -c nixi ipc call nixi conceal
qs -c nixi ipc call nixi close
qs -c nixi ipc call nixi setEnabled true
qs -c nixi ipc call nixi setEnabled false

qs -c nixi ipc call nixi open home
qs -c nixi ipc call nixi open notifications
qs -c nixi ipc call nixi open battery
qs -c nixi ipc call nixi open performance
qs -c nixi ipc call nixi open clipboard
qs -c nixi ipc call nixi open launcher

qs -c nixi ipc call nixi action notifications.dnd.toggle ""
qs -c nixi ipc call nixi action notifications.current.dismiss ""
qs -c nixi ipc call nixi action audio.output.mute.toggle ""
qs -c nixi ipc call nixi action animation.toggle ""
qs -c nixi ipc call nixi setPowerProfile saver
qs -c nixi ipc call nixi setPowerProfile balanced
qs -c nixi ipc call nixi setPowerProfile performance
qs -c nixi ipc call nixi cyclePowerProfile
```

`close` is suitable for a universal Escape binding. It closes a popup before a
page, then restores that page's captured home-or-hidden destination.

The Bluetooth hardware-key report is an optimistic UI hint for machines where
rfkill changes before BlueZ catches up:

```kdl
XF86Bluetooth allow-when-locked=true repeat=false {
    spawn "qs" "-c" "nixi" "ipc" "call" "nixi" "reportBluetoothKey";
}
```

## Authentication and PolicyKit

Nixi registers a PolicyKit authentication agent. Privileged requests use a
separate full-screen modal with exclusive keyboard focus; authentication is not
part of surface navigation. The modal handles hidden passwords, visible
challenges, multi-step PAM conversations, retry, submit, and cancellation.

Enable PolicyKit on NixOS and ensure Nixi is the only authentication agent:

```nix
{
  security.polkit.enable = true;
  environment.systemPackages = [ inputs.nixi.packages.${pkgs.system}.default ];
}
```

Verify it with `pkexec /usr/bin/true`. A missing prompt usually means another
PolicyKit agent already owns the session.

## Notifications

Nixi implements `org.freedesktop.Notifications`. Popups are queued and retained
as history after timeout. Hovering or expanding a popup pauses its timer.
Critical notifications are prioritized. Do Not Disturb suppresses normal
popups and all sounds; critical popups bypass DND by default but remain silent.

Preview or select critical sounds through the generic action endpoint:

```bash
qs -c nixi ipc call nixi action notifications.sound.preview short-notice
qs -c nixi ipc call nixi action notifications.sound.preview plucky
qs -c nixi ipc call nixi action notifications.sound.select echoed-ding
```

## Batteries and Niri

`services/PowerService.qml` exposes UPower data for up to two physical laptop
batteries. `services/BatteryWarnings.qml` sends one critical desktop
notification per discharging pack at the configured threshold and rearms after
recovery.

`services/CompositorService.qml` subscribes directly to Niri's JSON event stream
over `$NIRI_SOCKET`. Overview state temporarily forces home content without
changing the user's stored surface state.

## Configuration

- `core/Settings.qml` — behavior, timeouts, thresholds, and policy.
- `core/Theme.qml` — colors, spacing, typography, dimensions, and radii.
- `core/Motion.qml` — animation timing and the global motion switch.
- `core/SurfaceLayout.qml` — content identity to geometry mapping.

## Security boundaries

Lock and login UIs must remain separate from the pill:

- A lock screen needs a Wayland session-lock surface and dedicated lifecycle.
- A login screen needs a separate greeter entry point launched before Niri.
- Destructive session actions should gain an explicit confirmation modal.

## Validation

```bash
nix flake check
qs -p ./shell.qml
```

Quickshell reloads the configuration as files change. Watch its log and
exercise the relevant IPC action or service event after architectural changes.
