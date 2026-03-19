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
    ;

  # Recursively find all directories containing SKILL.md
  findSkillPaths =
    path:
    let
      entries = builtins.readDir path;
      hasSkillMd = entries ? "SKILL.md" && entries."SKILL.md" == "regular";
      subdirs = lib.filterAttrs (_: v: v == "directory") entries;
    in
    if hasSkillMd then
      [ path ]
    else
      lib.concatLists (lib.mapAttrsToList (name: _: findSkillPaths "${path}/${name}") subdirs);

  allSkillPaths = lib.concatLists (
    lib.mapAttrsToList (name: _: findSkillPaths "${inputs.team-claude-skills}/${name}") (
      lib.filterAttrs (_: v: v == "directory") (builtins.readDir inputs.team-claude-skills)
    )
  );
in
{
  options.modules.ai.team-skills = {
    enable = mkEnableOption "Enable team Claude skills from the shared skills repository";
  };

  config = mkIf cfg.enable {
    home.file = lib.listToAttrs (
      map (skillPath: {
        name = ".claude/skills/${builtins.unsafeDiscardStringContext (builtins.baseNameOf skillPath)}";
        value = {
          source = skillPath;
        };
      }) allSkillPaths
    );
  };
}
