{
  flake.modules.nixos.shiina = { config, lib, pkgs, modulesPath, ... }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
      initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ "kvm-intel" ];
    };

    nixpkgs.hostPlatform = "x86_64-linux";
    networking.useDHCP = lib.mkDefault true;
    networking.hostName = "shiina";

    # VA-API driver for the UHD 620 (Kaby Lake); without it browsers decode
    # all video on the CPU.
    hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

    services.fwupd.enable = true;
    hardware.cpu.intel.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
