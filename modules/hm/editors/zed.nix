{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.editors;
  inherit (lib) mkIf mkEnableOption;
in
{
  options.modules.editors.zed.enable = mkEnableOption "Enable Zed" // {
    default = true;
  };

  config = mkIf cfg.zed.enable {
    programs.zed-editor = {
      enable = true;
      extraPackages = with pkgs; [
        nil
        yaml-language-server
        nodePackages.vscode-json-languageserver
        package-version-server
      ];
      extensions = [
        "nix"
        "base16"
        "toml"
        "docker-compose"
        "git-firefly"
        "html"
        "log"
        "markdown"
        "proto"
      ];
      userSettings = {
        # Appearance
        ui_font_size = lib.mkForce 16;
        buffer_font_size = lib.mkForce 16;

        # Editor behavior
        vim_mode = true;
        autosave = "on_focus_change";
        format_on_save = "on";
        relative_line_numbers = true;
        cursor_blink = false;
        vertical_scroll_margin = 5;

        # Global formatter - treefmt handles all languages via project config
        formatter = {
          external = {
            command = "treefmt";
            arguments = [
              "--stdin"
              "{buffer_path}"
            ];
          };
        };

        scrollbar = {
          show = "never";
        };

        # Indent guides
        indent_guides = {
          enabled = true;
          coloring = "indent_aware";
          background_coloring = "indent_aware";
        };

        # Terminal
        terminal = {
          font_size = 14;
          copy_on_select = true;
        };

        # Panels docked right
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

        # Agent (replaces deprecated assistant)
        agent = {
          enabled = true;
          default_model = {
            provider = "zed.dev";
            model = "claude-sonnet-4";
          };
        };

        # Language configs
        languages = {
          Nix = {
            language_servers = [
              "!nixd"
              "nil"
            ];
          };
        };
      };
    };
  };
}
