{
  flake.modules.nixos.security.security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraConfig = "Defaults lecture = never";
  };
}
