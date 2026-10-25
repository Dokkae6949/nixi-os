# Gruvbox dark for GTK 2/3/4 (libadwaita included, through gtk-4.0/gtk.css),
# plus the desktop-wide dark and 24-hour preferences that the portal hands to
# browsers, Electron and GNOME apps.
{
  flake.modules.homeManager.theme = { config, pkgs, ... }: {
    gtk = {
      enable = true;
      colorScheme = "dark";
      theme = {
        name = "Gruvbox-Dark";
        package = pkgs.gruvbox-gtk-theme;
      };
      iconTheme = {
        name = "Gruvbox-Plus-Dark";
        package = pkgs.gruvbox-plus-icons;
      };
      gtk4.theme = config.gtk.theme;
    };

    dconf.settings."org/gnome/desktop/interface".clock-format = "24h";
  };
}
