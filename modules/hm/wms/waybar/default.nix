{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.secondfront.hyprland.waybar;
  inherit (config.lib.stylix) colors;
in
{
  options = {
    secondfront.hyprland.waybar.enable = mkEnableOption "Enable waybar" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          reload_style_on_change = true;
          layer = "top";
          position = "top";
          spacing = 0;
          height = 26;

          modules-left = [
            "custom/nix"
            "hyprland/workspaces"
          ];
          modules-center = [
            "clock"
          ];
          modules-right = [
            "group/tray-expander"
            "custom/lock"
            "bluetooth"
            "network"
            "pulseaudio"
            "cpu"
            "battery"
          ];

          "hyprland/workspaces" = {
            on-click = "activate";
            show-special = true;
            format = "{icon}";
            format-icons = {
              default = "";
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "0";
              active = "";
              "spotify" = "<span color='#${colors.base0B}'>󰓇</span>";
              "obs" = "<span color='#${colors.base08}'></span>";
              "chat" = "<span color='#${colors.base0C}'>󰭹</span>";
              "browser" = "<span color='#${colors.base09}'></span>";
              "monitor" = "<span color='#${colors.base0D}'>󱌣</span>";
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
            };
          };

          "custom/nix" = {
            format = "󱄅";
            on-click = "fuzzel";
            on-click-right = "system-menu";
            tooltip-format = "Left: App Launcher\nRight: System Menu";
          };

          "custom/lock" = {
            format = "";
            on-click = "loginctl lock-session && ${pkgs.hyprlock}/bin/hyprlock";
            tooltip = false;
          };

          "group/tray-expander" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 600;
              children-class = "tray-group-item";
            };
            modules = [
              "custom/expand-icon"
              "tray"
            ];
          };

          "custom/expand-icon" = {
            format = "󰅂";
            tooltip = false;
          };

          tray = {
            icon-size = 12;
            spacing = 17;
          };

          cpu = {
            interval = 5;
            format = "󰍛";
            on-click = "${pkgs.kitty}/bin/kitty -e ${pkgs.btop}/bin/btop";
          };

          clock = {
            format = "{:L%A %H:%M}";
            format-alt = "{:L%d %B W%V %Y}";
            tooltip = false;
          };

          network = {
            format-icons = [
              "󰢜"
              "󰢟"
              "󰢝"
              "󰢞"
              "󰢘"
            ];
            format = "{icon}";
            format-wifi = "{icon}";
            format-ethernet = "󰌘";
            format-disconnected = "󰢘";
            tooltip-format-wifi = "{essid} ({frequency} GHz)\n↓{bandwidthDownBytes}  ↑{bandwidthUpBytes}";
            tooltip-format-ethernet = "↓{bandwidthDownBytes}  ↑{bandwidthUpBytes}";
            tooltip-format-disconnected = "Disconnected";
            interval = 3;
            spacing = 1;
            on-click = "${pkgs.kitty}/bin/kitty -e ${pkgs.networkmanager}/bin/nmtui";
          };

          battery = {
            format = "{capacity}% {icon}";
            format-discharging = "{icon}";
            format-charging = "{icon}";
            format-plugged = "🔌";
            format-icons = {
              charging = [
                "󰢜"
                "󰢟"
                "󰢝"
                "󰢞"
                "󰢘"
                "󰂆"
                "󰂇"
                "󰂈"
                "󰢜"
              ];
              default = [
                "󰂎"
                "󰂏"
                "󰂐"
                "󰂑"
                "󰂒"
                "󰂓"
                "󰂔"
                "󰂕"
                "󰂖"
                "󰂗"
              ];
            };
            format-full = "󰢜";
            tooltip-format-discharging = "{power:>1.0f}W ⬇ {capacity}%";
            tooltip-format-charging = "{power:>1.0f}W ⬆ {capacity}%";
            interval = 5;
            states = {
              warning = 20;
              critical = 10;
            };
          };

          bluetooth = {
            format = "󰂯";
            format-disabled = "󰂰";
            format-connected = "󰂱";
            format-no-controller = "";
            tooltip-format = "Devices connected: {num_connections}";
            on-click = "${pkgs.blueman}/bin/blueman-manager";
          };

          pulseaudio = {
            format = "{icon}";
            on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
            on-click-right = "${pkgs.pamixer}/bin/pamixer -t";
            tooltip-format = "Playing at {volume}%";
            scroll-step = 5;
            format-muted = "󰖁";
            format-icons = {
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
            };
          };
        };
      };
      style = builtins.readFile ./waybar.css;
    };
  };
}
