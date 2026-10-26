{
  flake.modules.nixos.clock = {
    services.automatic-timezoned.enable = true;
    # geoclue's Wi-Fi source scans via wpa_supplicant, which is useless under
    # iwd, and the NixOS module never writes an [ip] section, so geoclue ends
    # up with no sources at all. Enable GeoIP against BeaconDB (wifi url).
    environment.etc."geoclue/conf.d/90-ip.conf".text = ''
      [ip]
      enable=true
      method=ichnaea
    '';
    # 24-hour times (and day-first dates) for everything that formats by locale.
    i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";
  };
}
