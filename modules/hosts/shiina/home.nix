# Host-specific Home Manager settings, applied to every user on Shiina.
{
  flake.modules.homeManager.shiina = {
    wayland.windowManager.niri.settings._children = [
      {
        output = {
          _args = [ "eDP-1" ];
          mode = "1920x1080@60.020";
          scale = 1;
          position._props = { x = 0; y = 0; };
        };
      }
    ];

    # The UHD 620 has no AV1 decoder, so AV1 streams (YouTube's default)
    # fall back to software decode. Refusing AV1 makes sites serve VP9/H.264,
    # which VA-API handles in hardware.
    programs.firefox.policies.Preferences."media.av1.enabled" = {
      Value = false;
      Status = "default";
    };
  };
}
