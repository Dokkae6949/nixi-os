{ config, ... }:

{
  flake.modules.nixos.desktop.imports = with config.flake.modules.nixos; [
    keyboard
    niri
  ];

  flake.modules.homeManager.desktop.imports = with config.flake.modules.homeManager; [
    browsers
    communication
    fonts
    niri
    quickshell
    spotify
    terminal
  ];
}
