{ config, lib, ... }:
with lib;
let
  cfg = config.modules.hyprpaper;
in
{
  options.modules.hyprpaper = {
    enable = mkEnableOption "Enable hyprpaper" // {
      default = true;
    };
    wallpaper = mkOption {
      type = types.str;
      default = "~/Wallpapers/Igris.png";
      description = "Path to wallpaper image";
    };
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        wallpaper = {
          monitor = "";
          path = cfg.wallpaper;
          fit_mode = "cover";
        };
      };
    };
  };
}
