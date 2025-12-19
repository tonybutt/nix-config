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
        nixfmt-rfc-style
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
      ];
      userSettings = {
        # Appearance
        ui_font_size = lib.mkForce 16;
        buffer_font_size = lib.mkForce 16;

        # Editor behavior
        vim_mode = true;
        autosave = "on_focus_change";
        relative_line_numbers = true;
        cursor_blink = false;
        vertical_scroll_margin = 5;

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
            formatter = {
              external = {
                command = "nixfmt";
              };
            };
          };
        };
      };
    };
  };
}
