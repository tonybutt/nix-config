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

  hooksConfig = {
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
      pkgs.python3
      claude-cognitive-init
    ];

    home.sessionVariables = {
      CLAUDE_INSTANCE = cfg.instanceId;
    };

    home.file = {
      ".claude-cognitive" = {
        source = claude-cognitive-src;
        recursive = true;
      };

      ".claude/scripts" = {
        source = "${claude-cognitive-src}/scripts";
        recursive = true;
      };

      ".claude/settings.json" = {
        text = builtins.toJSON hooksConfig;
      };
    };
  };
}
