{ inputs, lib, ... }:

{
  flake.modules.nixos.nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        flake-registry = "";
        trusted-users = [ "root" "@wheel" ];
        # Profiles and channels under ~/.local/state instead of ~/.nix-*.
        use-xdg-base-directories = true;
        nix-path = lib.mapAttrsToList (name: _: "${name}=flake:${name}") flakeInputs;
      };

      # Weekly, catching up after the machine was off; keeps two weeks of
      # generations to roll back to.
      gc = {
        automatic = true;
        dates = "weekly";
        persistent = true;
        options = "--delete-older-than 14d";
      };

      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    };

    nixpkgs.config.allowUnfree = true;

    # Needs a channel's programs.sqlite; nix-index (below) replaces it.
    programs.command-not-found.enable = false;
  };

  # `, <program> [args]` runs any program from nixpkgs without installing it,
  # and unknown commands suggest the package that provides them. Both use the
  # prebuilt weekly nix-index database, so nothing is indexed locally.
  flake.modules.homeManager.nix = {
    imports = [ inputs.nix-index-database.homeModules.nix-index ];

    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
  };
}
