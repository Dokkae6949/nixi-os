{
  flake.modules.homeManager.communication = { pkgs, ... }:
    let
      # Electron does not recognize Niri as a desktop with a Secret Service
      # implementation and would fall back to a plaintext key store.
      signal = pkgs.symlinkJoin {
        inherit (pkgs.signal-desktop) name meta;
        paths = [ pkgs.signal-desktop ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/signal-desktop \
            --add-flags "--password-store=gnome-libsecret"
        '';
      };
    in
    {
      programs.vesktop.enable = true;

      xdg.mimeApps = {
        enable = true;
        defaultApplications."x-scheme-handler/discord" = "vesktop.desktop";
      };

      home.packages = [
        signal
        pkgs.fastmail-desktop
      ];
    };
}
