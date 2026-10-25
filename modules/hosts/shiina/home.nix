# Host-specific Home Manager settings, applied to every user on Shiina.
{
  flake.modules.homeManager.shiina.wayland.windowManager.niri.settings._children = [
    {
      output = {
        _args = [ "eDP-1" ];
        mode = "1920x1080@60.020";
        scale = 1;
        position._props = { x = 0; y = 0; };
      };
    }
  ];
}
