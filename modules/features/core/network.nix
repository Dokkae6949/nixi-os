{
  flake.modules.nixos.network = { lib, options, pkgs, ... }: {
    config = lib.mkMerge [
      {
        # NetworkManager stays in charge (Nixi Shell's bar talks to it), but
        # drives Wi-Fi through iwd instead of wpa_supplicant: faster connects
        # and roaming. impala is the TUI on top of iwd.
        networking.networkmanager = {
          enable = true;
          dns = "systemd-resolved";
          wifi.backend = "iwd";
        };

        # No WWAN hardware on any current host.
        networking.modemmanager.enable = false;

        services.resolved.enable = true;

        # Speeds up boot time.
        systemd.services.NetworkManager-wait-online.enable = false;

        environment.systemPackages = with pkgs; [
          impala
        ];
      }

      (lib.optionalAttrs (options ? environment.persistence) {
        environment.persistence."/.persist".directories = [
          "/etc/NetworkManager/system-connections"
          "/var/lib/iwd"
        ];
      })
    ];
  };
}
