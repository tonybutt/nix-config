{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.ai.claude-cognitive;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  claude-cognitive-src = pkgs.fetchFromGitHub {
    owner = "GMaN1911";
    repo = "claude-cognitive";
    rev = "main";
    sha256 = "1pli7np432pzx2f1sasq369xlhjm3f1lpwllv4v8c080ngizqq0z";
  };

  settingsConfig = {
    permissions = {
      allow = [
        "Bash(echo:*)"
        "Bash(cat:*)"
        "Bash(head:*)"
        "Bash(printf:*)"
        "Bash(grep:*)"
        "Bash(nix fmt:*)"
        "Bash(nh os build:*)"
        "Bash(nh os switch:*)"
        "Bash(nh home build:*)"
        "Bash(nh home switch:*)"
        "Bash(git status:*)"
        "Bash(git diff:*)"
        "Bash(git log:*)"
        "Bash(git add:*)"
        "Bash(git commit:*)"
        "Bash(git restore:*)"
        "WebFetch(domain:raw.githubusercontent.com)"
        "mcp__figma__get_design_context"
        "mcp__figma__get_screenshot"
      ];
    };
    hooks = {
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "python3 ~/.claude/scripts/context-router-v2.py";
            }
            {
              type = "command";
              command = "python3 ~/.claude/scripts/pool-auto-update.py";
            }
          ];
        }
      ];
      SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "python3 ~/.claude/scripts/pool-loader.py";
            }
          ];
        }
      ];
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "python3 ~/.claude/scripts/pool-extractor.py";
            }
          ];
        }
      ];
    };
  };

  settingsJson = pkgs.writeText "claude-settings.json" (builtins.toJSON settingsConfig);

  claude-cognitive-init = pkgs.writeShellApplication {
    name = "claude-cognitive-init";
    text = builtins.readFile ./claude-cognitive-init.sh;
  };
  pythonWithDeps = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
in
{
  options.modules.ai.claude-cognitive = {
    enable = mkEnableOption "Enable Claude Cognitive - persistent working memory for Claude Code";

    instanceId = mkOption {
      type = types.str;
      default = "A";
      description = "The Claude instance identifier (A, B, C, etc.) for multi-instance coordination";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pythonWithDeps
      claude-cognitive-init
    ];

    home.sessionVariables = {
      CLAUDE_INSTANCE = cfg.instanceId;
    };

    # Keep cognitive templates as symlinks (only used by init script)
    home.file.".claude-cognitive" = {
      source = claude-cognitive-src;
      recursive = true;
    };

    # Copy files instead of symlinking so Claude can read them
    home.activation.claude-cognitive-files = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.claude/scripts"

      # Copy scripts (dereference symlinks, force overwrite)
      run cp -rLf "${claude-cognitive-src}/scripts/." "$HOME/.claude/scripts/"
      run chmod -R u+w "$HOME/.claude/scripts"

      # Copy settings.json
      run cp -Lf "${settingsJson}" "$HOME/.claude/settings.json"
      run chmod u+w "$HOME/.claude/settings.json"
    '';
  };
}
