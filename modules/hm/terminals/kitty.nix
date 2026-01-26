{ config, lib, ... }:
let
  cfg = config.secondfront.terminals;
  inherit (lib) mkIf mkEnableOption;
in
{
  options = {
    secondfront.terminals.kitty.enable = mkEnableOption "Enable Kitty terminal" // {
      default = true;
    };
  };
  config = mkIf cfg.kitty.enable {
    programs.kitty = {
      enable = true;
      extraConfig = ''
        allow_remote_control yes
      '';
    };
  };
}
