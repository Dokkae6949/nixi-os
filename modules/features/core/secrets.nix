{ inputs, ... }:

{
  flake.modules.nixos.secrets = { lib, options, ... }: {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    config = lib.optionalAttrs (options ? environment.persistence) {
      # Read the key straight from the persistent subvolume: secrets marked
      # `neededForUsers` are decrypted before impermanence bind mounts exist.
      sops.age.keyFile = "/.persist/var/lib/sops/age/keys.txt";
      environment.persistence."/.persist".directories = [ "/var/lib/sops" ];
    };
  };

  flake.modules.homeManager.secrets = { pkgs, ... }: {
    home.packages = [ pkgs.sops ];
  };
}
