{
  programs.waybar.settings.mainBar."hyprland/workspaces".persistent-workspaces = {
    "1" = [ "DP-4" ];
    "2" = [ "DP-4" ];
    "3" = [ "DP-4" ];
    "4" = [ "DP-4" ];
    "5" = [ "DP-4" ];
    "6" = [ "DP-3" ];
    "7" = [ "DP-3" ];
    "8" = [ "DP-3" ];
    "9" = [ "DP-3" ];
    "10" = [ "DP-3" ];
  };

  wayland.windowManager.hyprland.settings.workspace = [
    "1, monitor:DP-4, default:true"
    "2, monitor:DP-4"
    "3, monitor:DP-4"
    "4, monitor:DP-4"
    "5, monitor:DP-4"
    "6, monitor:DP-3, default:true"
    "7, monitor:DP-3"
    "8, monitor:DP-3"
    "9, monitor:DP-3"
    "10, monitor:DP-3"
  ];
  modules = {
    hyprpaper.wallpaper = "${../../modules/stylix/assets/walls/FF.png}";
    hyprland.monitors = [
      {
        name = "eDP-2";
        resolution = "highres@highrr";
        scale = "1.25";
        enabled = false;
      }
      {
        name = "DP-4";
        position = "0x0";
      }
      {
        name = "DP-3";
        position = "auto-right";
        resolution = "highres@high";
      }
    ];
  };
}
