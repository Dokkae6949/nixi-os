{ inputs, ... }:

# Nixi Shell, the Quickshell shell of nixi-os for Niri: one persistent
# full-width bar, a launcher (apps, session commands, clipboard),
# notifications, on-screen displays, lock screen and PolicyKit prompt. Its QML
# source lives in ./_qml; the leading underscore keeps import-tree from
# treating it as modules.
#
# For live development without rebuilding:
#   nix develop .#nixi-shell -c qs -p modules/features/desktop/nixi-shell/_qml/shell.qml
{
  flake.modules.homeManager.nixi-shell = { pkgs, ... }: {
    # gdbus: Idle.qml watches logind for sleep and lock requests.
    home.packages = [ pkgs.glib.bin ];

    programs.quickshell = {
      enable = true;
      package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      configs.nixi-shell = ./_qml;
      activeConfig = "nixi-shell";
      systemd.enable = true;
    };
  };

  perSystem = { inputs', pkgs, ... }: {
    devShells.nixi-shell = pkgs.mkShell {
      packages = [
        inputs'.quickshell.packages.default
        pkgs.qt6.qtdeclarative
      ];
    };
  };
}
