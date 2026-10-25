# The Niri Wayland session: compositor, session plumbing, and the small CLI
# helpers its keybindings call. The shell itself (bar, launcher, lock) is
# Quickshell; compositor settings live in settings.nix and binds.nix.
{
  flake.modules.nixos.niri = { pkgs, ... }: {
    programs.niri.enable = true;

    # Secret Service provider for browsers and Electron apps.
    services.gnome.gnome-keyring.enable = true;

    # Let the `video` group write backlight brightness directly, so
    # brightnessctl in keybindings never depends on logind's session state.
    services.udev.packages = [ pkgs.brightnessctl ];

    environment.systemPackages = with pkgs; [
      brightnessctl
      playerctl
      wl-clipboard
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };

  flake.modules.homeManager.niri = { pkgs, ... }: {
    wayland.windowManager.niri = {
      enable = true;
      # Same derivation as the system package; used to validate config.kdl at
      # build time. Session units and portals come from the NixOS module.
      package = pkgs.niri;
      systemd.enable = false;
      portalPackage = null;
    };

    services.cliphist.enable = true;

    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };
}
