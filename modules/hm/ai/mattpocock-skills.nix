{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.ai.mattpocock-skills;
  inherit (lib)
    mkIf
    mkEnableOption
    ;
in
{
  options.modules.ai.mattpocock-skills = {
    enable = mkEnableOption "Enable Matt Pocock's skills plugin for Claude Code";
  };

  config = mkIf cfg.enable {
    home.file.".claude/plugins/mattpocock-skills".source = inputs.mattpocock-skills;

    modules.ai.claude-settings = {
      enabledPlugins."mattpocock-skills@mattpocock" = true;
      extraKnownMarketplaces.mattpocock.source = {
        source = "directory";
        path = "${config.home.homeDirectory}/.claude/plugins/mattpocock-skills";
      };
    };
  };
}
