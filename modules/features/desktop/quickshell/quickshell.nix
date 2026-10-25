{ inputs, ... }:

# Nixi, the keyboard-first Quickshell shell for Niri (bar, launcher, lock,
# notifications, clipboard). Its QML source lives in ./_nixi; the leading
# underscore keeps import-tree from treating it as modules.
#
# For live development without rebuilding:
#   nix develop .#quickshell -c qs -p modules/features/desktop/quickshell/_nixi/shell.qml
{
  flake.modules.homeManager.quickshell = { pkgs, ... }: {
    programs.quickshell = {
      enable = true;
      package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      configs.nixi = ./_nixi;
      activeConfig = "nixi";
      systemd.enable = true;
    };
  };

  perSystem = { inputs', pkgs, ... }: {
    devShells.quickshell = pkgs.mkShell {
      packages = [
        inputs'.quickshell.packages.default
        pkgs.qt6.qtdeclarative
      ];
    };
  };
}
