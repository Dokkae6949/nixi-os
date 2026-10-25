{ config, ... }:

{
  flake.modules.nixos.base.imports = with config.flake.modules.nixos; [
    clock
    network
    nix
    secrets
    security
    shell
  ];

  flake.modules.homeManager.base.imports = with config.flake.modules.homeManager; [
    git
    shell
  ];
}
