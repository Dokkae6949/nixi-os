{ config, ... }:

{
  flake.modules.nixos.desktop.imports = with config.flake.modules.nixos; [
    greeter
    keyboard
    niri
  ];

  flake.modules.homeManager.desktop.imports = with config.flake.modules.homeManager; [
    browsers
    communication
    fonts
    niri
    nixi-shell
    spotify
    terminal
  ];
}
