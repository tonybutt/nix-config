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
          icon-size = 24;
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
          format = "{:%H:%M}  ";
          format-alt = "{:%A, %B %d, %Y (%R)}  ";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "tz_up";
            on-scroll-down = "tz_down";
            # on-scroll-up = "shift_up";
            # on-scroll-down = "shift_down";
          };
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
        "memory" = {
          interval = 30;
          format = "{used:0.1f}G/{total:0.1f}G ";
        };
      };
    };
    style = lib.mkAfter (builtins.readFile ./waybar.css);
  };
}
