{ config, ... }:

{
  flake.modules.nixos.development.imports = with config.flake.modules.nixos; [
    nix-ld
    podman
  ];

  flake.modules.homeManager.development.imports = with config.flake.modules.homeManager; [
    direnv
    helix
    secrets
    claude
  ];
}
