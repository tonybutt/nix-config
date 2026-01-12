{ lib, ... }:
{
  modules.hyprland.monitors = lib.mkForce [
    {
      enabled = false;
      name = "eDP-1";
      resolution = {
        width = 1920;
        height = 1080;
        refreshRate = 60;
      };
      position = "auto-left";
    }
    {
      name = "DP-1";
      resolution = {
        width = 2560;
        height = 1440;
        refreshRate = 60;
      };
      position = "0x0";
    }
    {
      name = "HDMI-A-1";
      resolution = {
        width = 3840;
        height = 2160;
        refreshRate = 60;
      };
      position = "auto-right";
    }
  ];
}
