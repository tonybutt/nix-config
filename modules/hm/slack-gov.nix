{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.slack-gov;
  inherit (lib) mkIf mkEnableOption;

  # The Slack desktop client runs in exactly one environment per profile:
  # clientEnvironment in <user-data-dir>/local-settings.json is 1000 for
  # commercial slack.com and 1001 for GovSlack (slack-gov.com). Give GovSlack
  # its own profile, pre-seeded into Gov mode so sign-in happens in-app
  # against slack-gov.com instead of via a slack:// browser handoff (which
  # would land in the commercial instance and could flip it into Gov mode).
  # Seed only when the file is absent; after first launch the app owns it.
  slack-gov = pkgs.writeShellScriptBin "slack-gov" ''
    data_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/SlackGov"
    if [ ! -e "$data_dir/local-settings.json" ]; then
      mkdir -p "$data_dir"
      echo '{"clientEnvironment":"1001"}' > "$data_dir/local-settings.json"
    fi
    exec ${pkgs.slack}/bin/slack --user-data-dir="$data_dir" "$@"
  '';
in
{
  options.modules.slack-gov = {
    enable = mkEnableOption "GovSlack desktop client (separate Gov-mode Slack profile)";
  };

  config = mkIf cfg.enable {
    home.packages = [ slack-gov ];

    # No x-scheme-handler/slack MimeType here: the commercial Slack desktop
    # entry stays the default handler for slack:// links.
    xdg.desktopEntries.slack-gov = {
      name = "GovSlack";
      comment = "Slack for GovSlack (slack-gov.com) workspaces";
      exec = "${lib.getExe slack-gov} %U";
      icon = "slack";
      terminal = false;
      categories = [
        "Network"
        "InstantMessaging"
      ];
    };
  };
}
