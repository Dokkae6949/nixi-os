{
  flake.modules.nixos.shell.programs.fish.enable = true;

  flake.modules.homeManager.shell = { pkgs, ... }: {
    home.packages = [ pkgs.htop ];

    programs.eza.enable = true;

    # `cat` with syntax highlighting: no line numbers, header, or pager. When
    # output is piped, bat falls back to plain `cat` behavior on its own.
    programs.bat = {
      enable = true;
      config = {
        style = "plain";
        paging = "never";
      };
    };

    programs.btop = {
      enable = true;
      settings = {
        color_theme = "gruvbox_dark_v2";
        proc_sorting = "cpu direct";
      };
    };

    programs.zellij = {
      enable = true;
      settings = {
        theme = "gruvbox-dark";
        pane_frames = false;
      };
    };

    programs.starship = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.fish = {
      enable = true;
      shellInit = "set fish_greeting";

      # `loadenv [FILE]`: export a dotenv file into the current shell.
      functions.loadenv = builtins.readFile ./loadenv.fish;

      shellAliases = {
        cat = "bat";
        l = "eza -l --all --color=always --icons=always --git --group-directories-first";
        ll = "eza -l --color=always --icons=always --git --group-directories-first";
        ls = "eza --grid --color=always --icons=always --group-directories-first";
        lt = "eza --tree -l --color=always --icons=always --git --group-directories-first";
      };
    };
  };
}
