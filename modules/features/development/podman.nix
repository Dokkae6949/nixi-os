{
  flake.modules.nixos.podman = {pkgs, ...}: {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    environment.systemPackages = with pkgs; [
      podman-compose
    ];
  };
}
