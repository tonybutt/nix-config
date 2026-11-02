{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.ai.rtk;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  rtk = lib.getExe cfg.package;
  instructions = pkgs.runCommand "rtk-instructions" { } ''
    export HOME="$TMPDIR"
    export XDG_CONFIG_HOME="$TMPDIR/.config"
    export XDG_DATA_HOME="$TMPDIR/.local/share"
    ${rtk} init --global --auto-patch --no-trust-filters < /dev/null
    install -Dm644 "$HOME/.claude/RTK.md" "$out"
  '';
in
{
  options.modules.ai.rtk = {
    enable = mkEnableOption "Enable rtk - CLI proxy that condenses command output for Claude Code";

    package = mkOption {
      type = types.package;
      default = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.rtk;
      description = "The rtk package to install";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];
      file.".claude/RTK.md".source = instructions;
      file.".claude/CLAUDE.md".text = "@RTK.md";
    };

    modules.ai.claude-settings.hooks.PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "${rtk} hook claude";
          }
        ];
      }
    ];
  };
}
