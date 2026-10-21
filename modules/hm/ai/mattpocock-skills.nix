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
    enable = mkEnableOption "Matt Pocock's skills as read-only reference, not loaded by Claude Code";
  };

  config = mkIf cfg.enable {
    # Outside ~/.claude so Claude Code never discovers them
    xdg.dataFile."reference/mattpocock-skills".source = inputs.mattpocock-skills;

    # The settings activation deep-merges and cannot delete keys, so an
    # earlier `true` survives unless explicitly overwritten
    modules.ai.claude-settings.enabledPlugins."mattpocock-skills@mattpocock" = false;
  };
}
