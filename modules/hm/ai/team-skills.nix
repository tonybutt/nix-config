{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.ai.team-skills;
  inherit (lib)
    mkIf
    mkEnableOption
    ;

  skills = inputs.team-claude-skills.packages.${pkgs.stdenv.hostPlatform.system};
  managedSkills = inputs.team-claude-skills.lib.managedSkillNames;
in
{
  options.modules.ai.team-skills = {
    enable = mkEnableOption "Enable team Claude skills from the shared skills repository";
  };

  config = mkIf cfg.enable {
    # Use cp -rL activation instead of home.file symlinks because
    # Claude Code's skill discovery does not follow symlinks.
    home.activation.claude-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/.claude/skills
      for skill in ${lib.concatStringsSep " " managedSkills}; do
        rm -rf $HOME/.claude/skills/$skill
      done
      cp -rL ${skills.claude-skills-all}/share/claude-skills/* $HOME/.claude/skills/
      chmod -R u+rw $HOME/.claude/skills
    '';
  };
}
