{
  flake.modules.nixos.network = { lib, options, ... }: {
    config = lib.mkMerge [
      {
        networking.networkmanager = {
          enable = true;
          dns = "systemd-resolved";
        };

        # No WWAN hardware on any current host.
        networking.modemmanager.enable = false;

        services.resolved.enable = true;

        # Speeds up boot time.
        systemd.services.NetworkManager-wait-online.enable = false;
      }

      (lib.optionalAttrs (options ? environment.persistence) {
        environment.persistence."/.persist".directories = [
          "/etc/NetworkManager/system-connections"
        ];
      })
    ];
  };
}
