# GNOME Files (Nautilus) as the file manager and the file chooser. Apps that
# open files through the FileChooser portal get xdg-desktop-portal-gnome,
# which hands the dialog to Nautilus when it is installed.
{
  flake.modules.nixos.files = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.nautilus ];
    # Trash, removable/MTP devices and network locations in Nautilus.
    services.gvfs.enable = true;
  };

  flake.modules.homeManager.files = {
    xdg.mimeApps.defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop";

    # Mount USB drives as they are plugged in, under /run/media/$USER, and say
    # so through Nixi Shell's notifications. There is no tray in the bar, and
    # a tray icon would make the service wait for a tray.target forever.
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
      tray = "never";
    };
  };
}
