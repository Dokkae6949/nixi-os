{
  flake.modules.nixos.shiina.boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # Disallow editing the kernel command line (init=/bin/sh) at boot.
        editor = false;
        # Keep the 1 GiB ESP from filling up with old kernels and initrds.
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      # Boot straight into the default entry. Hold Space during boot to get
      # the menu and pick an older generation.
      timeout = 0;
    };
  };
}
