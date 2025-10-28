{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.secondfront.editors;
  inherit (lib) mkIf mkEnableOption;
in
{
  options = {
    secondfront.editors.zed.enable = mkEnableOption "Enable Zed" // {
      default = true;
    };
  };
  config = mkIf cfg.zed.enable {
    programs.zed-editor = {
      enable = true;
      extraPackages = with pkgs; [
        nil
        nixfmt-rfc-style
        yaml-language-server
        nodePackages.vscode-json-languageserver
        package-version-server
      ];
      extensions = [
        "nix"
        "base16"
        "toml"
        "docker"
        "docker compose"
        "git firefly"
      ];
      userSettings = {
        languages = {
          Nix = {
            language_servers = [
              "!nixd"
              "nil"
            ];
            formatter = {
              external = {
                command = "nixfmt";
              };
            };
          };
        };
        assistant = {
          enabled = true;
          version = "2";
          default_model = {
            provider = "zed.dev";
            model = "claude-3-7-sonnet-latest";
          };
        };
        auto_update = false;
        ui_font_size = lib.mkForce 16;
        buffer_font_size = lib.mkForce 16;
        vim_mode = true;
        autosave = "on_focus_change";
        relative_line_numbers = true;
        git_panel = {
          dock = "right";
        };
        project_panel = {
          dock = "right";
        };
        collaboration_panel = {
          dock = "right";
        };
        outline_panel = {
          dock = "right";
        };
      };
    };
  };
}
