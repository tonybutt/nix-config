{
  programs.waybar.settings.mainBar."hyprland/workspaces".persistent-workspaces = {
    "1" = [ "DP-1" ];
    "2" = [ "DP-1" ];
    "3" = [ "DP-1" ];
    "4" = [ "DP-1" ];
    "5" = [ "DP-1" ];
    "6" = [ "HDMI-A-1" ];
    "7" = [ "HDMI-A-1" ];
    "8" = [ "HDMI-A-1" ];
    "9" = [ "HDMI-A-1" ];
    "10" = [ "HDMI-A-1" ];
  };

  wayland.windowManager.hyprland.settings.workspace = [
    "1, monitor:DP-1, default:true"
    "2, monitor:DP-1"
    "3, monitor:DP-1"
    "4, monitor:DP-1"
    "5, monitor:DP-1"
    "6, monitor:HDMI-A-1, default:true"
    "7, monitor:HDMI-A-1"
    "8, monitor:HDMI-A-1"
    "9, monitor:HDMI-A-1"
    "10, monitor:HDMI-A-1"
  ];

  modules = {
    hyprland.monitors = [
      {
        name = "eDP-1";
        enabled = false;
      }
      {
        name = "DP-1";
        position = "0x0";
      }
      {
        name = "HDMI-A-1";
        position = "auto-right";
      }
    ];
  };
}
