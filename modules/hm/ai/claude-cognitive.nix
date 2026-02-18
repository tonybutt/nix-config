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
    sha256 = "sha256-2/cKcDexmJdQzHrN77BTigOTfaPCsyqWl6QwlC9UgsY=";
  };

  pythonWithDeps = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);

  claude-cognitive-init = pkgs.writeShellApplication {
    name = "claude-cognitive-init";
    text = builtins.readFile ./claude-cognitive-init.sh;
  };

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

    # Cognitive templates (used by init script)
    home.file.".claude-cognitive" = {
      source = claude-cognitive-src;
      recursive = true;
    };

    # Scripts as symlinks into the Nix store
    home.file.".claude/scripts" = {
      source = "${claude-cognitive-src}/scripts";
      recursive = true;
    };

    # Contribute permissions and hooks to shared settings
    modules.ai.claude-settings = {
      permissions.allow = [
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
      hooks = {
        UserPromptSubmit = [
          {
            hooks = [
              {
                type = "command";
                command = "${pythonWithDeps}/bin/python3 ~/.claude/scripts/context-router-v2.py";
              }
              {
                type = "command";
                command = "${pythonWithDeps}/bin/python3 ~/.claude/scripts/pool-auto-update.py";
              }
            ];
          }
        ];
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "${pythonWithDeps}/bin/python3 ~/.claude/scripts/pool-loader.py";
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${pythonWithDeps}/bin/python3 ~/.claude/scripts/pool-extractor.py";
              }
            ];
          }
        ];
      };
    };
  };
}
