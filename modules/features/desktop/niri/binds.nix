{
  flake.modules.homeManager.niri = { lib, ... }:
    let
      # Talk to the running Nixi Shell over Quickshell IPC.
      nixiWith = props: args: {
        _props = {
          allow-when-locked = false;
          repeat = false;
        } // props;
        spawn = [ "qs" "-c" "nixi-shell" "ipc" "call" "nixi-shell" ] ++ args;
      };
      nixi = nixiWith { };
      # Hardware keys: usable on the lock screen and auto-repeating.
      shellKey = nixiWith { allow-when-locked = true; repeat = true; };

      whenLocked = action: { _props.allow-when-locked = true; } // action;

      workspaces = lib.range 1 9;
    in
    {
      wayland.windowManager.niri.settings.binds = {
        "Mod+Shift+ssharp".show-hotkey-overlay = { };
        "Mod+Q" = {
          _props.hotkey-overlay-title = "Open a Terminal: alacritty";
          spawn = "alacritty";
        };
        "Mod+O" = { _props.repeat = false; toggle-overview = { }; };
        "Mod+Shift+Q" = { _props.repeat = false; close-window = { }; };
        "Mod+Escape" = {
          _props.allow-inhibiting = false;
          toggle-keyboard-shortcuts-inhibit = { };
        };
        "Ctrl+Alt+Delete".quit = { };
        "Mod+Shift+P".power-off-monitors = { };

        # Media and hardware keys. Volume, microphone and brightness go
        # through Nixi Shell (native PipeWire and sysfs) so its OSD follows.
        "XF86AudioRaiseVolume" = shellKey [ "volumeUp" "5" ];
        "XF86AudioLowerVolume" = shellKey [ "volumeDown" "5" ];
        "XF86AudioMute" = nixiWith { allow-when-locked = true; } [ "volumeMute" ];
        "XF86AudioMicMute" = nixiWith { allow-when-locked = true; } [ "micMute" ];
        "XF86MonBrightnessUp" = shellKey [ "brightnessUp" "5" ];
        "XF86MonBrightnessDown" = shellKey [ "brightnessDown" "5" ];
        "Shift+XF86MonBrightnessUp" = shellKey [ "brightnessUp" "1" ];
        "Shift+XF86MonBrightnessDown" = shellKey [ "brightnessDown" "1" ];
        "XF86AudioPlay" = whenLocked { spawn = [ "playerctl" "play-pause" ]; };
        "XF86AudioStop" = whenLocked { spawn = [ "playerctl" "stop" ]; };
        "XF86AudioPrev" = whenLocked { spawn = [ "playerctl" "previous" ]; };
        "XF86AudioNext" = whenLocked { spawn = [ "playerctl" "next" ]; };
        "Alt+Ctrl+Home" = whenLocked { spawn = [ "playerctl" "previous" ]; };
        "Alt+Ctrl+End" = whenLocked { spawn = [ "playerctl" "play-pause" ]; };
        "Alt+Ctrl+Insert" = whenLocked { spawn = [ "playerctl" "next" ]; };

        # Nixi Shell.
        "XF86Tools" = nixiWith { allow-when-locked = true; } [ "cyclePowerProfile" ];
        "XF86Favorites" = nixiWith { allow-when-locked = true; } [ "dnd" ];
        "Mod+D" = nixi [ "launcher" ];
        "Alt+V" = nixi [ "clipboard" ];
        "Mod+N" = nixi [ "notifications" ];
        "Mod+Shift+N" = nixiWith { hotkey-overlay-title = "Dismiss Notification"; } [ "dismiss" ];
        "Mod+B" = nixi [ "battery" ];
        "Mod+X" = nixi [ "close" ];
        "Ctrl+Alt+Backspace" = nixi [ "lock" ];
        "Super+Alt+L" = nixiWith { hotkey-overlay-title = "Lock the Screen"; } [ "lock" ];

        # Focus and movement.
        "Mod+H".focus-column-left = { };
        "Mod+J".focus-window-or-workspace-down = { };
        "Mod+K".focus-window-or-workspace-up = { };
        "Mod+L".focus-column-right = { };
        "Mod+Ctrl+H".move-column-left = { };
        "Mod+Ctrl+J".move-window-down-or-to-workspace-down = { };
        "Mod+Ctrl+K".move-window-up-or-to-workspace-up = { };
        "Mod+Ctrl+L".move-column-right = { };
        "Mod+Home".focus-column-first = { };
        "Mod+End".focus-column-last = { };
        "Mod+Ctrl+Home".move-column-to-first = { };
        "Mod+Ctrl+End".move-column-to-last = { };

        "Mod+Shift+H".focus-monitor-left = { };
        "Mod+Shift+J".focus-monitor-down = { };
        "Mod+Shift+K".focus-monitor-up = { };
        "Mod+Shift+L".focus-monitor-right = { };
        "Mod+Shift+Ctrl+H".move-column-to-monitor-left = { };
        "Mod+Shift+Ctrl+J".move-column-to-monitor-down = { };
        "Mod+Shift+Ctrl+K".move-column-to-monitor-up = { };
        "Mod+Shift+Ctrl+L".move-column-to-monitor-right = { };

        "Mod+Page_Down".focus-workspace-down = { };
        "Mod+Page_Up".focus-workspace-up = { };
        "Mod+Ctrl+Page_Down".move-column-to-workspace-down = { };
        "Mod+Ctrl+Page_Up".move-column-to-workspace-up = { };
        "Mod+Shift+Page_Down".move-workspace-down = { };
        "Mod+Shift+Page_Up".move-workspace-up = { };
        "Mod+Shift+U".move-workspace-down = { };
        "Mod+Shift+I".move-workspace-up = { };

        "Mod+WheelScrollDown" = { _props.cooldown-ms = 150; focus-workspace-down = { }; };
        "Mod+WheelScrollUp" = { _props.cooldown-ms = 150; focus-workspace-up = { }; };
        "Mod+Ctrl+WheelScrollDown" = { _props.cooldown-ms = 150; move-column-to-workspace-down = { }; };
        "Mod+Ctrl+WheelScrollUp" = { _props.cooldown-ms = 150; move-column-to-workspace-up = { }; };
        "Mod+WheelScrollRight".focus-column-right = { };
        "Mod+WheelScrollLeft".focus-column-left = { };
        "Mod+Ctrl+WheelScrollRight".move-column-right = { };
        "Mod+Ctrl+WheelScrollLeft".move-column-left = { };
        "Mod+Shift+WheelScrollDown".focus-column-right = { };
        "Mod+Shift+WheelScrollUp".focus-column-left = { };
        "Mod+Ctrl+Shift+WheelScrollDown".move-column-right = { };
        "Mod+Ctrl+Shift+WheelScrollUp".move-column-left = { };

        # Columns and windows.
        "Mod+Comma".consume-or-expel-window-left = { };
        "Mod+Period".consume-or-expel-window-right = { };
        "Mod+R".switch-preset-column-width = { };
        "Mod+Shift+R".switch-preset-window-height = { };
        "Mod+Ctrl+R".reset-window-height = { };
        "Mod+F".maximize-column = { };
        "Mod+Shift+F".maximize-window-to-edges = { };
        "Mod+Ctrl+F".expand-column-to-available-width = { };
        "Mod+C".center-column = { };
        "Mod+Ctrl+C".center-visible-columns = { };
        "Mod+Left".set-column-width = "-10%";
        "Mod+Right".set-column-width = "+10%";
        "Mod+Down".set-window-height = "-10%";
        "Mod+Up".set-window-height = "+10%";
        "Mod+V".toggle-window-floating = { };
        "Mod+Shift+V".switch-focus-between-floating-and-tiling = { };
        "Mod+W".toggle-column-tabbed-display = { };

        # Screenshots.
        "Print".screenshot = { };
        "Ctrl+Print".screenshot-screen = { };
        "Alt+Print".screenshot-window = { };
      }
      // lib.listToAttrs (map (n: lib.nameValuePair "Mod+${toString n}" { focus-workspace = n; }) workspaces)
      // lib.listToAttrs (map (n: lib.nameValuePair "Mod+Shift+${toString n}" { move-column-to-workspace = n; }) workspaces);
    };
}
