{
  flake.modules.nixos.power = {
    services.upower.enable = true;

    services.tlp = {
      enable = true;
      pd.enable = true;
    };
  };
}
