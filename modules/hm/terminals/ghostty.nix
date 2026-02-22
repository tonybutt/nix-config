{ config, lib, ... }:
let
  cfg = config.modules.terminals;
  inherit (lib) mkIf mkEnableOption;
in
{
  options = {
    modules.terminals.ghostty.enable = mkEnableOption "Enable Ghostty terminal" // {
      default = false;
    };
  };
  config = mkIf cfg.ghostty.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        font-family = "FiraMono Nerd Font Mono";
        font-size = 14;
        window-decoration = false;
      };
    };
  };
}
