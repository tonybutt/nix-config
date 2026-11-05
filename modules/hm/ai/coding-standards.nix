{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.ai.coding-standards;
  inherit (lib)
    getExe
    mkIf
    mkEnableOption
    ;

  standards = inputs.standards.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.modules.ai.coding-standards = {
    enable = mkEnableOption "Enable the coding-standards Claude skills and the standards installer CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [ standards ];

    # The installer writes real files, which Claude Code's skill discovery
    # needs; clearing first drops skills for topics that were removed.
    home.activation.coding-standards-skills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf $HOME/.claude/skills/coding-standards-*
      ${getExe standards} install
    '';
  };
}
