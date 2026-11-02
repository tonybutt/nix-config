{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.ai.superpowers;
  inherit (lib)
    mkIf
    mkEnableOption
    ;
in
{
  options.modules.ai.superpowers = {
    enable = mkEnableOption "Enable the superpowers plugin for Claude Code";
  };

  config = lib.mkMerge [
    { modules.ai.claude-settings.enabledPlugins."superpowers@superpowers-dev" = cfg.enable; }
    (mkIf cfg.enable {
      home.file.".claude/plugins/superpowers".source = inputs.superpowers;

      modules.ai.claude-settings.extraKnownMarketplaces.superpowers-dev.source = {
        source = "directory";
        path = "${config.home.homeDirectory}/.claude/plugins/superpowers";
      };
    })
  ];
}
