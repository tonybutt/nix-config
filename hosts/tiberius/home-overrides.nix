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

  wayland.windowManager.hyprland.settings.workspace_rule =
    let
      onMonitor = monitor: ws: {
        workspace = toString ws;
        inherit monitor;
      };
    in
    [
      (onMonitor "DP-1" 1 // { default = true; })
      (onMonitor "DP-1" 2)
      (onMonitor "DP-1" 3)
      (onMonitor "DP-1" 4)
      (onMonitor "DP-1" 5)
      (onMonitor "HDMI-A-1" 6 // { default = true; })
      (onMonitor "HDMI-A-1" 7)
      (onMonitor "HDMI-A-1" 8)
      (onMonitor "HDMI-A-1" 9)
      (onMonitor "HDMI-A-1" 10)
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
