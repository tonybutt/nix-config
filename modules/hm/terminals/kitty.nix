{ config, lib, ... }:
let
  cfg = config.modules.terminals;
  inherit (lib) mkIf mkEnableOption;
in
{
  options = {
    modules.terminals.kitty.enable = mkEnableOption "Enable Kitty terminal" // {
      default = true;
    };
  };
  config = mkIf cfg.kitty.enable {
    programs.kitty = {
      enable = true;
      extraConfig = ''
        allow_remote_control yes
        font_size 16.0
      '';
    };
  };
}
