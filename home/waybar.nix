{ lib, ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "group/hardware"
          "clock"
        ];
        "hyprland/workspaces" = {
          show-special = true;
          format = "{name} {windows}";
          format-window-separator = " ";
          window-rewrite-default = "";
          window-rewrite = {
            "class<dev.zed.Zed>" = ""; # Windows whose titles contain "youtube"
            "class<firefox>" = ""; # Windows whose classes are "firefox"
            "class<firefox> title<.*github.*>" = ""; # Windows whose class is "firefox" and title contains "github". Note that "class" always comes first.
            "foot" = ""; # Windows that contain "foot" in either class or title. For optimization reasons, it will only match against a title if at least one other window explicitly matches against a title.
            "code" = "󰨞";
          };
        };
        "hyprland/window" = {
          format = " {title}";
        };
        "group/hardware" = {
          orientation = "horizontal";
          modules = [
            "battery"
            "cpu"
            "memory"
          ];
          drawer = {
            transition-duration = 500;
          };
        };
        "memory" = { };
        "clock" = {
          interval = 60;
          format = "  {:%a %b %d    %I:%M %p}"; # %b %d %Y  --Date formatting
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d %H:%M:%S  }";
        };
        "battery" = {
          bat = "BAT1";
          interval = 60;
          states = {
            "warning" = 30;
            "critical" = 1;
          };
          format = "{icon} {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          max-length = 25;
        };
        "cpu" = {
          interval = 1;
          format = "{icon} {usage}%";
          format-icons = [
            "<span color='#69ff94'>▁</span>" # green
            "<span color='#2aa9ff'>▂</span>" # blue
            "<span color='#f8f8f2'>▃</span>" # white
            "<span color='#f8f8f2'>▄</span>" # white
            "<span color='#ffffa5'>▅</span>" # yellow
            "<span color='#ffffa5'>▆</span>" # yellow
            "<span color='#ff9977'>▇</span>" # orange
            "<span color='#dd532e'>█</span>" # red
          ];
        };
      };
    };
    style = lib.mkAfter (builtins.readFile ./waybar.css);
  };
}
