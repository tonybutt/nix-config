{
  pkgs,
  config,
  lib,
  user,
  ...
}:
let
  cfg = config.modules.git;
  inherit (lib) mkIf mkEnableOption;
  commitTemplate = ./commit-template.txt;
in
{
  options = {
    modules.git.enable = mkEnableOption "Enable git configuration" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.forgejo-cli
      pkgs.gh
    ];
    # fj only offers browser login for hosts it has an OAuth client ID for.
    # Forgejo auto-registers a public "tea" app (oauth2.DEFAULT_APPLICATIONS)
    # whose loopback redirect accepts fj's http://127.0.0.1:26218/.
    xdg.configFile."forgejo-cli/client_ids".text = ''
      code.grail.tiberius.com d57cb8c4-630c-4168-8324-ec79935e18d4
    '';
    programs.git = {
      package = pkgs.gitFull;
      enable = true;
      signing = {
        key = user.work.signingKey;
        signByDefault = true;
        format = "ssh";
      };
      includes = [
        # Personal repos via SSH
        {
          condition = "hasconfig:remote.*.url:git@github.com:${user.personal.githubUsername}/**";
          contents = {
            user.email = user.personal.email;
            user.signingKey = user.personal.signingKey;
          };
        }
        # Personal repos via HTTPS
        {
          condition = "hasconfig:remote.*.url:https://github.com/${user.personal.githubUsername}/**";
          contents = {
            user.email = user.personal.email;
            user.signingKey = user.personal.signingKey;
          };
        }
      ];
      settings = {
        user.email = user.work.email;
        user.name = user.fullName;
        user.signingKey = user.work.signingKey;
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
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };
    };
  };
}
