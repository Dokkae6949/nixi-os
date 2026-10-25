{ config, inputs, ... }:

{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.shiina = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      base
      laptop
      desktop
      development
      impermanence
      tailscale
      kurisu
      shiina

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          # Move pre-existing unmanaged dotfiles aside instead of failing.
          backupFileExtension = "hm-backup";
          users.kurisu.imports = with config.flake.modules.homeManager; [
            base
            desktop
            development
            kurisu
            shiina
          ];
        };
      }
    ];
  };
}
