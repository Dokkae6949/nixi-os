{
  flake.modules.nixos.shiina = { config, lib, modulesPath, ... }: {
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

    services.fwupd.enable = true;
    hardware.cpu.intel.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
