{
  flake.modules.homeManager.claude = { pkgs, ... }: {
    home.packages = [ pkgs.claude-code ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };
}
