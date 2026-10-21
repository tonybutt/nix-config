{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  watchman = lib.getExe config.services.watchman.package;
in
{
  imports = [ inputs.watchman.homeManagerModules.default ];

  programs.waybar.settings.mainBar = {
    modules-right = lib.mkBefore [ "custom/watchman" ];
    "custom/watchman" = {
      exec = "${watchman} waybar";
      return-type = "json";
      interval = 30;
      format = "watchman {}";
      on-click = "${lib.getExe pkgs.kitty} --class watchman -e ${watchman} tui";
    };
  };

  programs.waybar.style = lib.mkAfter ''
    #custom-watchman {
      margin: 0 4px;
    }

    #custom-watchman.idle,
    #custom-watchman.ready {
      color: @base0B;
    }

    #custom-watchman.failed {
      color: @base0A;
    }

    #custom-watchman.error {
      color: @base08;
    }
  '';

  services.watchman = {
    enable = true;
    settings = {
      forgejo_url = "https://code.grail.tiberius.com";
      token_file = "/run/secrets/watchman-forgejo-token";
      approver_token_file = "/run/secrets/watchman-approver-token";
      review_skills = [
        "rfd-check"
        "pr-check"
        "watchman-standards"
        "rust-backend-pr"
        "go-backend-pr"
        "frontend-pr"
        "test-check"
      ];
      ignored_authors = [ "renovate-bot" ];
      rfd_repo = "grail/rfd";
      orgs = [ { name = "grail"; } ];
    };
  };
}
