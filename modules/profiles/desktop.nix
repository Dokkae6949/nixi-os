{ config, ... }:

{
  flake.modules.nixos.desktop.imports = with config.flake.modules.nixos; [
    files
    greeter
    keyboard
    niri
  ];

  flake.modules.homeManager.desktop.imports = with config.flake.modules.homeManager; [
    browsers
    communication
    files
    fonts
    niri
    nixi-shell
    spotify
    terminal
    theme
  ];
}
