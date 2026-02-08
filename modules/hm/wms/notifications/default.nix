{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.modules.hyprland.enable {
    services.mako.enable = true;
    services.mako.settings = {
      "default-timeout" = 5000;

      # Route Signal notifications to HDMI monitor
      "app-name=Signal" = {
        output = "HDMI-A-1";
      };
    };
  };
}
