{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.hyprland.waybar;
  inherit (config.lib.stylix) colors;
  webcamToggle = pkgs.writeShellScript "webcam-toggle" ''
    sudo /run/current-system/sw/bin/webcam-toggle toggle
    ${pkgs.procps}/bin/pkill -RTMIN+10 waybar
  '';

  webcamStatus = pkgs.writeShellScript "webcam-status" ''
    USB_IDS="0c45:6d50 046d:0946"
    found=0
    any_on=0
    in_use=0
    for id in $USB_IDS; do
      vid="''${id%%:*}"
      pid="''${id##*:}"
      for devpath in /sys/bus/usb/devices/*/idVendor; do
        dir="$(dirname "$devpath")"
        if [ -f "$dir/idVendor" ] && [ -f "$dir/idProduct" ] && [ -f "$dir/authorized" ] \
           && [ "$(cat "$dir/idVendor")" = "$vid" ] \
           && [ "$(cat "$dir/idProduct")" = "$pid" ]; then
          found=1
          if [ "$(cat "$dir/authorized")" = "1" ]; then
            any_on=1
            for vdir in "$dir"/*/video4linux/video*; do
              if [ -d "$vdir" ]; then
                vdev="/dev/$(basename "$vdir")"
                if [ -e "$vdev" ] && ${pkgs.psmisc}/bin/fuser "$vdev" >/dev/null 2>&1; then
                  in_use=1
                fi
              fi
            done
          fi
        fi
      done
    done
    if [ "$found" = "0" ]; then
      echo '{"text": "󰖠", "tooltip": "No cameras found", "class": "disconnected"}'
    elif [ "$any_on" = "0" ]; then
      echo '{"text": "󱜷", "tooltip": "Webcam muted", "class": "muted"}'
    elif [ "$in_use" = "1" ]; then
      echo '{"text": "󰖠", "tooltip": "Webcam in use", "class": "in-use"}'
    else
      echo '{"text": "󰖠", "tooltip": "Webcam available", "class": "available"}'
    fi
  '';

  pcStatus = pkgs.writeShellScript "pc-status" ''
    LABEL="$1"
    PORT="$2"
    PROCS="$3"
    TUNNEL_PROC="$4"

    RAW=$(${pkgs.process-compose}/bin/process-compose process list -o json -p "''${PORT}" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$RAW" ]; then
      echo "{\"text\": \"''${LABEL}: 󱎘\", \"tooltip\": \"''${LABEL}: not reachable\", \"class\": \"offline\"}"
      exit 0
    fi

    IFS=',' read -ra PROC_ARR <<< "''${PROCS}"
    TOTAL=0
    RUNNING=0
    TOOLTIP="''${LABEL}:"
    for proc in "''${PROC_ARR[@]}"; do
      STATUS=$(echo "$RAW" | ${pkgs.jq}/bin/jq -r --arg name "$proc" '.[] | select(.name == $name) | .status')
      TOTAL=$((TOTAL + 1))
      if [ "$STATUS" = "Running" ]; then
        RUNNING=$((RUNNING + 1))
        TOOLTIP="''${TOOLTIP}\n  ✓ ''${proc}"
      else
        TOOLTIP="''${TOOLTIP}\n  ✗ ''${proc} (''${STATUS:-unknown})"
      fi
    done

    if [ "$RUNNING" -eq "$TOTAL" ]; then
      ICON="󰐾"
      CLASS="online"
    elif [ "$RUNNING" -gt 0 ]; then
      ICON="󰍷"
      CLASS="degraded"
    else
      ICON="󱎘"
      CLASS="offline"
    fi

    TUNNEL=""
    if [ -n "''${TUNNEL_PROC}" ]; then
      TSTATUS=$(echo "$RAW" | ${pkgs.jq}/bin/jq -r --arg name "''${TUNNEL_PROC}" '.[] | select(.name == $name) | .status')
      if [ "$TSTATUS" = "Running" ]; then
        TUNNEL="<span color='#${colors.base09}'>󰅟</span> "
        TOOLTIP="''${TOOLTIP}\n  󰅟 tunnel active"
      fi
    fi

    TOOLTIP="''${TOOLTIP}\n  ''${RUNNING}/''${TOTAL} running"
    echo "{\"text\": \"''${TUNNEL}''${LABEL}: ''${ICON}\", \"tooltip\": \"''${TOOLTIP}\", \"class\": \"''${CLASS}\"}"
  '';
in
{
  options = {
    modules.hyprland.waybar.enable = mkEnableOption "Enable waybar" // {
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
          spacing = 4;
          height = 32;
          margin-left = 8;
          margin-right = 8;
          margin-top = 4;

          modules-left = [
            "custom/nix"
            "hyprland/workspaces"
          ];
          modules-center = [
            "hyprland/window"
            "clock"
          ];
          modules-right = [
            "custom/lethality"
            "custom/agility"
            "group/tray-expander"
            "custom/lock"
            "network"
            "bluetooth"
            "custom/webcam"
            "pulseaudio"
            "cpu"
            "memory"
            "temperature"
            "backlight"
            "battery"
          ];

          "hyprland/workspaces" = {
            on-click = "activate";
            all-outputs = false;
            show-special = true;
            format = "{name} {windows}";
            format-window-separator = " ";
            window-rewrite-default = "";
            window-rewrite = {
              "class<google-chrome>" = "<span color='#${colors.base09}'></span>";
              "class<brave-browser>" = "<span color='#${colors.base09}'>󰖟</span>";
              "class<firefox>" = "<span color='#${colors.base09}'></span>";
              "class<kitty>" = "<span color='#${colors.base0B}'>󰆍</span>";
              "class<com.mitchellh.ghostty>" = "<span color='#${colors.base0B}'></span>";
              "class<code>" = "<span color='#${colors.base0D}'>󰨞</span>";
              "class<slack>" = "<span color='#${colors.base0C}'>󰒱</span>";
              "class<Signal>" = "<span color='#${colors.base0C}'>󰭹</span>";
              "class<dev.zed.Zed>" = "<span color='#${colors.base0A}'>󱐋</span>";
              "class<spotify>" = "<span color='#${colors.base0B}'>󰓇</span>";
              "class<steam>" = "<span color='#${colors.base0D}'>󰓓</span>";
              "class<steam_app_.*>" = "<span color='#${colors.base0B}'>󰊗</span>";
              "class<gamescope>" = "<span color='#${colors.base0B}'>󰊗</span>";
              "title<(.*) - (.*) - Visual Studio Code>" = "<span color='#${colors.base0D}'>[󰨞 $2]</span>";
            };
            format-icons = {
              "spotify" = "<span color='#${colors.base0B}'>󰓇</span>";
              "obs" = "<span color='#${colors.base08}'></span>";
              "chat" = "<span color='#${colors.base0C}'>󰭹</span>";
              "browser" = "<span color='#${colors.base09}'></span>";
              "monitor" = "<span color='#${colors.base0D}'>󱌣</span>";
            };
          };

          "hyprland/window" = {
            format = "{class}";
            max-length = 20;
            rewrite = {
              "^(?!.*\\S).*" = "Desktop";
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
            tooltip-format = "Lock Screen";
          };

          "custom/webcam" = {
            exec = "${webcamStatus}";
            return-type = "json";
            interval = 2;
            signal = 10;
            on-click = "${pkgs.cameractrls-gtk4}/bin/cameractrlsgtk4";
            on-click-middle = "${webcamToggle}";
            on-click-right = "${webcamToggle}";
          };

          "custom/agility" = {
            exec = "${pcStatus} AGI 8088 backend,frontend,postgres,zitadel,openfga,rustfs,mailpit cloudflared";
            return-type = "json";
            interval = 5;
          };

          "custom/lethality" = {
            exec = "${pcStatus} LETH 8080 backend,frontend,postgres,openfga,rustfs,zitadel,zitadel-login,zitadel-db,golang-ai";
            return-type = "json";
            interval = 5;
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
            spacing = 16;
          };

          cpu = {
            interval = 5;
            format = "󰍛";
            format-alt = "󰍛 {usage}%";
            on-click-right = "${pkgs.kitty}/bin/kitty --class btop -e ${pkgs.btop}/bin/btop";
          };

          memory = {
            format = "󰑭";
            format-alt = "󰑭 {}%";
          };

          temperature = {
            critical-threshold = 80;
            format-critical = "{icon} {temperatureC}°C";
            format = "{icon}";
            format-alt = "{icon} {temperatureC}°C";
            format-icons = [
              "󰔏"
              "󰔏"
              "󰔐"
              "󰔑"
              "󰔒"
            ];
          };

          backlight = {
            format = "{icon}";
            format-alt = "{icon} {percent}%";
            format-icons = [
              "󰃚"
              "󰃛"
              "󰃜"
              "󰃝"
              "󰃞"
              "󰃟"
              "󰃠"
            ];
            tooltip-format = "Backlight: {percent}%";
          };

          clock = {
            format = "{:%a %d %b  %I:%M %p %Z}";
            timezones = [
              "America/New_York"
              "Etc/UTC"
            ];
            tooltip-format = "<tt>{calendar}</tt>";
            calendar = {
              mode = "month";
              on-scroll = 1;
              format = {
                today = "<span color='#${colors.base0B}'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-right = "tz_up";
            };
          };

          network = {
            format-icons = [
              "<span color='#${colors.base08}'>󰤯</span>"
              "<span color='#${colors.base09}'>󰤟</span>"
              "<span color='#${colors.base0A}'>󰤢</span>"
              "<span color='#${colors.base0C}'>󰤥</span>"
              "<span color='#${colors.base0B}'>󰤨</span>"
            ];
            format = "{icon}";
            format-wifi = "{icon}";
            format-ethernet = "<span color='#${colors.base0B}'>󰌘</span>";
            format-disconnected = "<span color='#${colors.base08}'>󰤭</span>";
            tooltip-format-wifi = "{essid} ({frequency} GHz)\n↓{bandwidthDownBytes}  ↑{bandwidthUpBytes}";
            tooltip-format-ethernet = "↓{bandwidthDownBytes}  ↑{bandwidthUpBytes}";
            tooltip-format-disconnected = "Disconnected";
            interval = 3;
            spacing = 1;
            on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
          };

          battery = {
            format = "{icon}";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰚥 {capacity}%";
            format-alt = "{icon} {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            format-full = "󱟢";
            tooltip-format = "{power}W {timeTo}";
            interval = 5;
            states = {
              warning = 30;
              critical = 15;
            };
          };

          bluetooth = {
            format = "󰂯";
            format-disabled = "󰂲";
            format-connected = "󰂱";
            format-no-controller = "󰂲";
            tooltip-format = "Devices connected: {num_connections}";
            on-click = "${pkgs.blueman}/bin/blueman-manager";
          };

          pulseaudio = {
            format = "{icon}";
            format-alt = "{icon}  {volume}% {format_source}";
            on-click-middle = "${pkgs.pamixer}/bin/pamixer -t";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            tooltip-format = "Playing at {volume}%";
            scroll-step = 5;
            format-muted = "󰝟";
            format-source = " {volume}%";
            format-source-muted = "󰝟";
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
