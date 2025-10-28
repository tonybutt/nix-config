{ config, lib, ... }:
with lib;
let
  cfg = config.secondfront.hyprland.hyprpaper;
in
{
  options = {
    secondfront.hyprland.hyprpaper.enable = mkEnableOption "Enable hyprpaper theme" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ ];
        wallpaper = [
          ",~/Wallpapers/Lavendar.png"
        ];
      };
    };
  };
}
