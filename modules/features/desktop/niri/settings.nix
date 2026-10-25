{
  flake.modules.homeManager.niri.wayland.windowManager.niri.settings = {
    input = {
      keyboard = {
        xkb = {
          layout = "at,us";
          variant = "nodeadkeys";
          options = "grp:win_space_toggle";
        };
        numlock = { };
      };

      touchpad = {
        tap = { };
        natural-scroll = { };
      };

      mouse = {
        accel-speed = -0.5;
        accel-profile = "flat";
      };

      focus-follows-mouse._props.max-scroll-amount = "33%";
    };

    gestures.hot-corners.off = { };

    # Gruvbox dark.
    layout = {
      gaps = 5;
      center-focused-column = "never";
      always-center-single-column = { };
      background-color = "#282828";

      preset-column-widths._children = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      default-column-width.proportion = 0.5;

      focus-ring.off = { };

      border = {
        width = 2;
        active-color = "#d3869b";
        inactive-color = "#3c3836";
        urgent-color = "#fb4934";
      };

      shadow = {
        on = { };
        softness = 30;
        spread = 5;
        offset._props = { x = 0; y = 6; };
        color = "#00000088";
        inactive-color = "#00000055";
      };

      tab-indicator = {
        width = 4;
        gap = 4;
        active-color = "#b8bb26";
        inactive-color = "#665c54";
        urgent-color = "#fb4934";
      };

      insert-hint.color = "#fabd2f80";
    };

    overview.zoom = 0.25;
    hotkey-overlay.skip-at-startup = { };
    prefer-no-csd = { };
    screenshot-path = "~/Pictures/screenshots/screenshot_%Y-%m-%d_%H-%M-%S.png";

    _children = [
      {
        window-rule._children = [
          { match._props = { app-id = "firefox$"; title = "^Picture-in-Picture$"; }; }
          { open-floating = true; }
        ];
      }
      {
        window-rule = {
          geometry-corner-radius = 0;
          clip-to-geometry = true;
        };
      }
    ];
  };
}
