{
  flake.modules.nixos.logging = { lib, options, ... }: {
    config = lib.mkMerge [
      {
        # Keep enough history to compare boots, but not forever.
        services.journald.settings.Journal = {
          SystemMaxUse = "500M";
          MaxRetentionSec = "1month";
        };
      }

      (lib.optionalAttrs (options ? environment.persistence) {
        environment.persistence."/.persist".directories = [ "/var/log" ];
      })
    ];
  };
}
