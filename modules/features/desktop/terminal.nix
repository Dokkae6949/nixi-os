{
  flake.modules.homeManager.terminal.programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";
      window.padding = { x = 5; y = 5; };
      font.normal.family = "JetBrainsMono Nerd Font";

      # Shift+Enter sends ESC+CR so TUI apps can tell it apart from Enter.
      keyboard.bindings = [
        { key = "Return"; mods = "Shift"; chars = builtins.fromJSON ''"\u001b\r"''; }
      ];

      # Gruvbox dark.
      colors = {
        primary = {
          background = "#282828";
          foreground = "#ebdbb2";
        };
        normal = {
          black = "#282828";
          red = "#cc241d";
          green = "#98971a";
          yellow = "#d79921";
          blue = "#458588";
          magenta = "#b16286";
          cyan = "#689d6a";
          white = "#a89984";
        };
        bright = {
          black = "#928374";
          red = "#fb4934";
          green = "#b8bb26";
          yellow = "#fabd2f";
          blue = "#83a598";
          magenta = "#d3869b";
          cyan = "#8ec07c";
          white = "#ebdbb2";
        };
      };
    };
  };
}
