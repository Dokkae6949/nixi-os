{
  flake.modules.nixos.shiina = {
    # throttled rewrites the voltage offsets from its own config on start and
    # on every power-source change, so the undervolt has to live here; a
    # separate undervolt service would be reset to 0 mV. Core and cache share
    # a voltage plane on Kaby Lake and must use the same offset.
    services.throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        Autoreload: True

        [BATTERY]
        Update_Rate_s: 30
        PL1_Tdp_W: 29
        PL1_Duration_s: 28
        PL2_Tdp_W: 44
        PL2_Duration_S: 0.002
        Trip_Temp_C: 85
        cTDP: 0
        Disable_BDPROCHOT: False

        [AC]
        Update_Rate_s: 5
        PL1_Tdp_W: 44
        PL1_Duration_s: 28
        PL2_Tdp_W: 44
        PL2_Duration_S: 0.002
        Trip_Temp_C: 95
        cTDP: 0
        Disable_BDPROCHOT: False

        [UNDERVOLT]
        CORE: -90
        GPU: -50
        CACHE: -90
        UNCORE: 0
        ANALOGIO: 0
      '';
    };

    services.tlp.settings = {
      CPU_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_MAX_PERF_ON_AC = 100;

      CPU_BOOST_ON_BAT = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_MAX_PERF_ON_BAT = 100;

      CPU_BOOST_ON_SAV = 0;
      CPU_HWP_DYN_BOOST_ON_SAV = 0;
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_MAX_PERF_ON_SAV = 60;

      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 85;
      START_CHARGE_THRESH_BAT1 = 80;
      STOP_CHARGE_THRESH_BAT1 = 85;
    };
  };
}
