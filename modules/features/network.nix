{
  flake.modules.nixos.network = {
    networking.networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };

    services.resolved.enable = true;

    systemd.services.NetworkManager-wait-online.enable = false;
  };

  flake.modules.nixos.networkPersistence = {
    environment.persistence."/.persist".directories = [
      "/etc/NetworkManager/system-connections"
    ];
  };
}
