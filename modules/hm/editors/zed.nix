{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.editors;
  inherit (lib) mkIf mkEnableOption;
  pkgs-color-lsp = import inputs.nixpkgs-color-lsp { inherit (pkgs) system; };
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
        tailwindcss-language-server
        typescript-language-server
        pkgs-color-lsp.color-lsp
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
        "color-highlight"
      ];
      userSettings = {
        # Appearance
        lsp_document_colors = "background";
        ui_font_size = lib.mkForce 16;
        buffer_font_size = lib.mkForce 16;

        # Editor behavior
        vim_mode = true;
        autosave = "on_focus_change";
        format_on_save = "on";
        relative_line_numbers = "enabled";
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
        languages =
          let
            language_servers = [
              "typescript-language-server"
              "color-lsp"
              "!vtsls"
            ];
          in
          {
            TypeScript = {
              inherit language_servers;
            };
            JavaScript = {
              inherit language_servers;
            };
            TSX = {
              inherit language_servers;
            };
            CSS = {
              language_servers = [
                "!vscode-css-languageserver"
                "tailwindcss-language-server"
              ];
            };
            Nix = {
              language_servers = [
                "!nixd"
                "color-lsp"
                "nil"
              ];
            };
          };
      };
    };
  };
}
