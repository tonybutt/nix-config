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
      userName = user.fullName;
      userEmail = user.email;
      signing = {
        key = user.signingkey;
        signByDefault = true;
        signer = "gpg";
      };
      extraConfig = {
        core.askPass = "";
        core.editor = "vim";
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
