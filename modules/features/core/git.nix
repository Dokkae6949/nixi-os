# Git behavior shared by everyone. Author identity lives in the user module.
{
  flake.modules.homeManager.git.programs = {
    git = {
      enable = true;
      settings = {
        merge.conflictStyle = "zdiff3";
        push.autoSetupRemote = true;
      };
    };

    difftastic = {
      enable = true;
      git.enable = true;
    };
  };
}
