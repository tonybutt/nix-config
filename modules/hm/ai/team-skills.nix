{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.ai.team-skills;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  options.modules.ai.team-skills = {
    enable = mkEnableOption "Enable team Claude skills from the shared skills repository";

    skills = mkOption {
      type = types.listOf types.str;
      default = [
        "rfd-check"
        "tiberius-development-workflow"
      ];
      description = "List of skill directory names to install from team-claude-skills";
    };
  };

  config = mkIf cfg.enable {
    home.file = lib.listToAttrs (
      map (skill: {
        name = ".claude/skills/${skill}";
        value = {
          source = "${inputs.team-claude-skills}/${skill}";
        };
      }) cfg.skills
    );
  };
}
