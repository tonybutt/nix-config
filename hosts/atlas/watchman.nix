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
    enable = false;
    settings = {
      forgejo_url = "https://code.grail.tiberius.com";
      token_file = "/run/secrets/watchman-forgejo-token";
      approver_token_file = "/run/secrets/watchman-approver-token";
      review_skills = [
        "rfd-check"
        "pr-check"
      ];
      ignored_authors = [ "renovate-bot" ];
      repos = map (name: { name = "grail/${name}"; }) [
        "agility"
        "arc-runner-nix"
        "argo-node-watcher"
        "assist"
        "auto-ato"
        "blackknight"
        "boarded"
        "bullhorn"
        "buzz-nix"
        "charter"
        "ci-test"
        "cmmc-ssp"
        "compliance"
        "comply-remake"
        "corpdata"
        "crm-salesforce-sync"
        "data"
        "docs"
        "doppler"
        "dsls-agent"
        "dsls-server"
        "effects"
        "effects-models"
        "employee-portal"
        "eso-vw"
        "fleet-mdm-test-vms"
        "fleet-policy-library"
        "FOOTPRINT"
        "forge-arc"
        "forgejo-policy"
        "forgejo-runner-nix"
        "forgejo-webhook-handler"
        "forgejo-workflows"
        "google-bucket-browser"
        "grail"
        "grail-fleet-proxies"
        "grail-it-bot"
        "grail-slack-agent-remote"
        "grail-status"
        "grailed"
        "home"
        "images"
        "inventory"
        "invictus-game"
        "ironHub"
        "localdev"
        "logistics"
        "pi-pxe-imager"
        "plm"
        "prek"
        "rfd"
        "rfd-site"
        "rfd-slack-bot"
        "roz"
        "slack-emoji"
        "squire"
        "stash"
        "swearjar"
        "synthetic-login"
        "tailscale-nixos"
        "team-claude-skills"
        "tiberius-20"
        "tiberius-com"
        "tiberius-fleet"
        "tiberius-onlyoffice"
        "TiberiusDrive"
        "TiberiusDrive-installer"
        "TiberiusNix"
        "TiberiusRemote"
        "tibsign"
        "tibui"
        "user-feedback"
        "wazuh"
        "wazuh-nix-flake"
        "workadventure"
        "workadventure-maps"
        "xport"
        "z9s"
      ];
    };
  };
}
