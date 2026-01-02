{
  pkgs,
  config,
  lib,
  user,
  ...
}:
let
  cfg = config.secondfront.git;
  inherit (lib) mkIf mkEnableOption;
  commitTemplate = ./commit-template.txt;
in
{
  options = {
    secondfront.git.enable = mkEnableOption "Enable git configuration" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    programs.git = {
      package = pkgs.gitFull;
      enable = true;
      signing = {
        key = user.signingkey;
        signByDefault = true;
        format = "ssh";
      };
      settings = {
        user.email = user.email;
        user.name = user.fullName;
        user.signingkey = "${user.signingkey}";
        core.askPass = "";
        core.editor = "vim";
        commit.template = "${commitTemplate}";
        init.defaultBranch = "main";
        credential.helper = "libsecret";
        push.autoSetupRemote = true;
        pull.rebase = true;
        merge.conflictStyle = "zdiff3";
        rebase.autosquash = true;
        rebase.autostash = true;
        commit.verbose = true;
        rerere.enabled = true;
        help.autocorrect = 10;
        diff.histogram = "histogram";
        core.pager = "${pkgs.delta}/bin/delta";
      };
    };
  };
}
