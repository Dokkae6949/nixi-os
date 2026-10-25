{
  flake.modules.nixos.clock = {
    services.automatic-timezoned.enable = true;
    # 24-hour times (and day-first dates) for everything that formats by locale.
    i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";
  };
}
