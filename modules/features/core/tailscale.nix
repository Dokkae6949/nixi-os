{
  flake.modules.nixos.tailscale = { lib, options, ... }: {
    config = lib.mkMerge [
      {
        services.tailscale = {
          enable = true;

          # Allow direct peer-to-peer connections instead of relying on DERP
          # when the local network permits UDP hole punching.
          openFirewall = true;
        };

        # Tailscale ACLs remain the network-level authorization boundary.
        # Trusting its interface lets services be reached without opening them
        # on LAN/WAN.
        networking.firewall.trustedInterfaces = [ "tailscale0" ];
      }

      # Node identity must survive reboots or the host re-enrolls every boot.
      (lib.optionalAttrs (options ? environment.persistence) {
        environment.persistence."/.persist".directories = [
          "/var/lib/tailscale"
        ];
      })
    ];
  };
}
