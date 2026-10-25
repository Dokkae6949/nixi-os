{
  # Available but off until toggled from the bar (or the Fn key).
  flake.modules.nixos.bluetooth.hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
}
