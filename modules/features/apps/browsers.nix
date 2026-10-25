{ inputs, ... }:

{
  flake.modules.homeManager.browsers = { config, lib, pkgs, ... }: {
    programs.firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
      policies.Preferences = {
        # File dialogs through the portal (Nautilus) instead of GTK's own.
        "widget.use-xdg-desktop-portal.file-picker" = { Value = 1; Status = "default"; };
        # Dates and times in the OS locale format (24-hour) rather than en-US.
        "intl.regional_prefs.use_os_locales" = { Value = true; Status = "default"; };
      };
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = lib.genAttrs [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ] (_: "firefox.desktop");
    };

    home.packages = [
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
