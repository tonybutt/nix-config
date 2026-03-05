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
        copy-on-select = "clipboard";
        clipboard-trim-trailing-spaces = true;
        font-family = "FiraMono Nerd Font Mono";
        font-size = 14;
        window-decoration = false;
        background-opacity = 0.8;
      };
    };
  };
}
