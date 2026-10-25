# Keep $HOME free of dotfiles: point tools that would otherwise create
# ~/.<tool> at the XDG base directories instead. Tools that hardcode their
# path (ssh, adb, kubectl, NSS's ~/.pki, Firefox's ~/.mozilla) stay put.
{
  flake.modules.homeManager.xdg-home = { config, ... }: {
    xdg.enable = true;

    home.sessionVariables = with config.xdg; {
      CARGO_HOME = "${dataHome}/cargo";
      GRADLE_USER_HOME = "${dataHome}/gradle";
      NPM_CONFIG_CACHE = "${cacheHome}/npm";
      DOCKER_CONFIG = "${configHome}/docker";

      # History files; these tools don't create missing directories.
      HISTFILE = "${stateHome}/bash_history";
      PSQL_HISTORY = "${stateHome}/psql_history";
      PYTHON_HISTORY = "${stateHome}/python_history";
      REDISCLI_HISTFILE = "${stateHome}/rediscli_history";
    };
  };
}
