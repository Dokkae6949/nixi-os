{
  flake.modules.homeManager.claude = { pkgs, ... }: {
    home.packages = with pkgs; [
      claude-code
    ];
  };
}
