{ config, ... }:

{
  flake.modules.nixos.base.imports = with config.flake.modules.nixos; [
    clock
    logging
    network
    nix
    secrets
    security
    shell
    shutdown
  ];

  flake.modules.homeManager.base.imports = with config.flake.modules.homeManager; [
    git
    nix
    shell
    xdg-home
  ];
}
