{ inputs, ... }:

# Opt-in ephemeral root. Selecting this module makes `environment.persistence`
# available; other features then contribute their own persistent state through
# `options ? environment.persistence` guards, so persistence is declared next
# to the software that needs it rather than in a central list.
{
  flake.modules.nixos.impermanence = { lib, ... }: {
    imports = [ inputs.impermanence.nixosModules.impermanence ];

    fileSystems."/.persist".neededForBoot = lib.mkDefault true;

    environment.persistence."/.persist" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/lib/nixos"
        "/var/lib/systemd/timers"
      ];
      files = [ "/etc/machine-id" ];
    };
  };
}
