{ config, lib, ... }:
with lib;
let
  cfg = config.modules.hypridle;
in
{
  options.modules.hypridle = {
    enable = mkEnableOption "Enable hypridle" // {
      default = true;
    };
    lockTimeout = mkOption {
      type = types.int;
      default = 300;
      description = "Seconds before locking screen";
    };
    screenOffTimeout = mkOption {
      type = types.int;
      default = 330;
      description = "Seconds before turning off screen";
    };
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          # Lock screen
          {
            timeout = cfg.lockTimeout;
            on-timeout = "loginctl lock-session";
          }
          # Screen off
          {
            timeout = cfg.screenOffTimeout;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
