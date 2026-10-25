{ inputs, ... }:

# The login screen. greetd starts a bare Niri as the `greeter` user; Niri runs
# the Nixi Shell greeter (_qml/greeter.qml), which shares its look with the
# lock screen. Picking a session and logging in quits Quickshell, the
# `niri msg action quit` after it ends the greeter's Niri, and greetd starts
# the chosen session. The greeter remembers the last user and session.
{
  flake.modules.nixos.greeter = { config, lib, options, pkgs, ... }:
    let
      quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      niri = config.programs.niri.package;
      stateDir = "/var/lib/nixi-greeter";

      # What the greeter offers. greetd runs `command` through `sh -c`, so it
      # is a shell command line, not an argv.
      sessions = pkgs.writeText "nixi-greeter-sessions.json" (builtins.toJSON [
        {
          name = "Niri";
          command = "niri-session";
          env = [ "XDG_SESSION_TYPE=wayland" ];
        }
        {
          name = "Shell";
          command = ''"$SHELL" -l'';
          env = [ "XDG_SESSION_TYPE=tty" ];
        }
      ]);

      # Keyboard layout must match the desktop's (niri/settings.nix), or
      # passwords typed here would differ from the ones typed on the lock screen.
      niriConfig = pkgs.writeText "nixi-greeter.kdl" ''
        input {
          keyboard {
            xkb {
              layout "at,us"
              variant "nodeadkeys"
              options "grp:win_space_toggle"
            }
            numlock
          }
          touchpad {
            tap
            natural-scroll
          }
        }
        cursor {
          xcursor-theme "Bibata-Modern-Classic"
          xcursor-size 24
        }
        hotkey-overlay {
          skip-at-startup
        }
        binds {
          XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "set" "5%+"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }
        }
        spawn-sh-at-startup "qs -p ${./_qml}/greeter.qml; niri msg action quit --skip-confirmation"
      '';

      greeter = pkgs.writeShellApplication {
        name = "nixi-greeter";
        runtimeInputs = [ quickshell niri pkgs.brightnessctl pkgs.dbus config.systemd.package ];
        text = ''
          export NIXI_GREETER_SESSIONS=${sessions}
          export NIXI_GREETER_STATE=${stateDir}/state.json
          export XDG_CACHE_HOME=${stateDir}/cache
          export XDG_STATE_HOME=${stateDir}/state

          # Log to the journal (`journalctl -t nixi-greeter`), not over tty1.
          exec systemd-cat -t nixi-greeter dbus-run-session niri -c ${niriConfig}
        '';
      };
    in
    lib.mkMerge [
      {
        services.greetd = {
          enable = true;
          settings.default_session = {
            user = "greeter";
            command = lib.getExe greeter;
          };
        };

        # Clear tty1 when greetd starts, so the gap between the greeter and the
        # session shows black instead of leftover boot logs.
        systemd.services.greetd.serviceConfig = {
          TTYPath = "/dev/tty1";
          TTYReset = true;
          TTYVTDisallocate = true;
        };

        # Keep kernel warnings off the console; systemd's boot status still shows.
        boot.consoleLogLevel = 3;

        # Brightness keys on the login screen (brightnessctl's udev rule).
        users.users.greeter.extraGroups = [ "video" ];

        systemd.tmpfiles.rules = [ "d ${stateDir} 0750 greeter greeter -" ];

        fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
        environment.systemPackages = [ pkgs.bibata-cursors ];
      }

      (lib.optionalAttrs (options ? environment.persistence) {
        environment.persistence."/.persist".directories = [
          {
            directory = stateDir;
            user = "greeter";
            group = "greeter";
            mode = "0750";
          }
        ];
      })
    ];
}
