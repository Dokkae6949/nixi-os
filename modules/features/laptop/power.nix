{
  flake.modules.nixos.power = {
    services.upower.enable = true;

    services.tlp = {
      enable = true;
      pd.enable = true;
    };

    # Closing the lid suspends, even on AC, unless an external display is
    # connected. Nixi Shell locks the screen before the machine goes down and
    # handles idle lock/blank/suspend itself (see nixi-shell/_qml/Idle.qml).
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };
  };
}
