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

  # Workaround for Zed's managed Node.js not working on NixOS.
  # Zed downloads a generic Linux node binary that fails due to missing dynamic linker.
  # We create a directory that symlinks to Nix's nodejs, with a writable cache dir.
  # See: https://github.com/zed-industries/zed/issues/50828#issuecomment-4031736186
  zedNodeVersion = "node-v24.11.0-linux-x64";
  zedNodeShim = pkgs.runCommand "zed-node-shim" { } ''
    mkdir -p $out
    for item in ${pkgs.nodejs}/bin ${pkgs.nodejs}/include ${pkgs.nodejs}/lib ${pkgs.nodejs}/share; do
      ln -s "$item" "$out/$(basename $item)"
    done
    ln -s ${config.home.homeDirectory}/.cache/zed-node $out/cache
  '';
in
{
  options.modules.editors.zed.enable = mkEnableOption "Enable Zed" // {
    default = true;
  };

  config = mkIf cfg.zed.enable {
    # Symlink Nix nodejs into the location Zed expects
    home.file.".local/share/zed/node/${zedNodeVersion}".source = zedNodeShim;

    programs.zed-editor = {
      enable = true;
      extraPackages = with pkgs; [
        nil
        vscode-langservers-extracted
        yaml-language-server
        vscode-json-languageserver
        package-version-server
        tailwindcss-language-server
        typescript-language-server
        pkgs-color-lsp.color-lsp
        slint-lsp
        claude-agent-acp
        docker-language-server
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
        "scss"
        "typst"
        "slint"
        "sql"
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
        agent_servers = {
          claude-acp = {
            type = "registry";
            env = {
              CLAUDE_CODE_EXECUTABLE = "${pkgs.claude-code}/bin/claude";
            };
          };
        };

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
        #
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
