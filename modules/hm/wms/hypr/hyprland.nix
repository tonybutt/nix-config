{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (builtins) map toString;

  # Binary paths
  kitty = "${pkgs.kitty}/bin/kitty";
  thunar = "${pkgs.xfce.thunar}/bin/thunar";
  fuzzel = "${pkgs.fuzzel}/bin/fuzzel";
  cliphist = "${pkgs.cliphist}/bin/cliphist";
  wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  grim = "${pkgs.grim}/bin/grim";
  slurp = "${pkgs.slurp}/bin/slurp";
  swappy = "${pkgs.swappy}/bin/swappy";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  btop = "${pkgs.btop}/bin/btop";
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  spotify = "${pkgs.spotify}/bin/spotify";
  obs = "${pkgs.obs-studio}/bin/obs";
  slack = "${pkgs.slack}/bin/slack";
  signal = "${pkgs.signal-desktop}/bin/signal-desktop";
  brave = "${pkgs.brave}/bin/brave";
in
{
  options = {
    modules.hyprland.enable = mkEnableOption "Enable hyprland window Manager" // {
      default = true;
    };
    modules.hyprland.monitors = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            transform = mkOption {
              type = types.bool;
              default = false;
            };
            name = mkOption {
              type = types.str;
              example = "DP-1";
            };

            resolution = mkOption {
              type = types.either types.str (
                types.submodule {
                  options = {
                    width = mkOption {
                      type = types.int;
                      example = 1920;
                    };
                    height = mkOption {
                      type = types.int;
                      example = 1080;
                    };
                    refreshRate = mkOption {
                      type = types.int;
                      default = 60;
                    };
                  };
                }
              );
              default = "preferred";
              example = "highres@highrr";
              description = ''
                Monitor resolution. Can be:
                - "highres@highrr" - Highest resolution at highest refresh rate
                - "preferred" - Use monitor's preferred mode
                - "auto" - Let Hyprland decide
                - { width = 1920; height = 1080; refreshRate = 60; } - Explicit resolution
              '';
            };

            # DEPRECATED: Keep for backwards compatibility
            width = mkOption {
              type = types.nullOr types.int;
              default = null;
            };
            height = mkOption {
              type = types.nullOr types.int;
              default = null;
            };
            refreshRate = mkOption {
              type = types.nullOr types.int;
              default = null;
            };

            scale = mkOption {
              type = types.str;
              default = "1";
            };
            position = mkOption {
              type = types.str;
              default = "auto";
            };
            enabled = mkOption {
              type = types.bool;
              default = true;
            };
            workspace = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
        }
      );
      default = [ ];
    };
    modules.hyprland.mainMod = mkOption {
      type = types.str;
      default = "SUPER";
      example = "CTRL";
      description = "The main modifier key for Hyprland bindings.";
    };
  };
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      xwayland.enable = true;
      systemd = {
        enable = true;
        variables = [ "--all" ];
      };
      settings =
        let
          inherit (config.lib.stylix) colors;
          rgb = color: "rgb(${color})";
          activeGradient = "${rgb colors.base0B} ${rgb colors.base0A} 45deg";
          inactiveGradient = "${rgb colors.base00}";

          # Helper function to build resolution string
          buildResolution =
            m:
            if builtins.isAttrs m.resolution then
              # Structured resolution
              "${toString m.resolution.width}x${toString m.resolution.height}@${toString m.resolution.refreshRate}"
            else if m.width != null && m.height != null then
              # Backwards compatibility
              "${toString m.width}x${toString m.height}@${
                toString (if m.refreshRate != null then m.refreshRate else 60)
              }"
            else
              # String resolution (preferred, auto, highres@highrr, etc.)
              m.resolution;
        in
        {
          "$mainMod" = cfg.mainMod;

          # Omarchy environment variables
          env = [
            # Cursor size
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
            # Force all apps to use Wayland
            "GDK_BACKEND,wayland,x11,*"
            "QT_QPA_PLATFORM,wayland;xcb"
            "QT_STYLE_OVERRIDE,kvantum"
            "SDL_VIDEODRIVER,wayland"
            "MOZ_ENABLE_WAYLAND,1"
            "ELECTRON_OZONE_PLATFORM_HINT,wayland"
            "OZONE_PLATFORM,wayland"
            "XDG_SESSION_TYPE,wayland"
            # Screen sharing support
            "XDG_CURRENT_DESKTOP,Hyprland"
            "XDG_SESSION_DESKTOP,Hyprland"
            # XCompose file
            "XCOMPOSEFILE,~/.XCompose"
          ];

          xwayland = {
            force_zero_scaling = true;
          };

          cursor = {
            no_hardware_cursors = true;
            hide_on_key_press = true;
          };

          ecosystem = {
            no_update_news = true;
          };

          # Omarchy input config
          input = {
            kb_layout = "us";
            kb_options = "compose:caps";
            repeat_rate = 40;
            repeat_delay = 600;
            numlock_by_default = true;
            follow_mouse = 1;
            sensitivity = 0;

            touchpad = {
              natural_scroll = false;
              scroll_factor = 0.4;
            };
          };

          monitor =
            (map (
              m:
              "${m.name},${
                if m.enabled then
                  if m.transform then
                    "transform,${toString m.scale}"
                  else
                    "${buildResolution m},${m.position},${toString m.scale}"
                else
                  "disable"
              }"
            ) (cfg.monitors))
            ++ [
              ",preferred,auto,1"
            ];

          # Omarchy look and feel
          general = {
            "col.active_border" = lib.mkDefault "${activeGradient}";
            "col.inactive_border" = lib.mkDefault "${inactiveGradient}";
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };

          decoration = {
            rounding = 0;

            shadow = {
              enabled = true;
              range = 2;
              render_power = 3;
            };

            blur = {
              enabled = true;
              size = 2;
              passes = 2;
              special = true;
              brightness = 0.60;
              contrast = 0.75;
            };
          };

          # Omarchy animations
          animations = {
            enabled = true;

            bezier = [
              "easeOutQuint,0.23,1,0.32,1"
              "easeInOutCubic,0.65,0.05,0.36,1"
              "linear,0,0,1,1"
              "almostLinear,0.5,0.5,0.75,1.0"
              "quick,0.15,0,0.1,1"
            ];

            animation = [
              "global, 1, 10, default"
              "border, 1, 5.39, easeOutQuint"
              "windows, 1, 4.79, easeOutQuint"
              "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
              "windowsOut, 1, 1.49, linear, popin 87%"
              "fadeIn, 1, 1.73, almostLinear"
              "fadeOut, 1, 1.46, almostLinear"
              "fade, 1, 3.03, quick"
              "layers, 1, 3.81, easeOutQuint"
              "layersIn, 1, 4, easeOutQuint, fade"
              "layersOut, 1, 1.5, linear, fade"
              "fadeLayersIn, 1, 1.79, almostLinear"
              "fadeLayersOut, 1, 1.39, almostLinear"
              "workspaces, 0, 0, easeOutQuint"
            ];
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
            force_split = 2; # Always split on the right
          };

          master = {
            new_status = "master";
          };

          group = {
            "col.border_active" = lib.mkDefault "${activeGradient}";
            "col.border_inactive" = lib.mkDefault "${inactiveGradient}";
            "col.border_locked_active" = lib.mkDefault "-1";
            "col.border_locked_inactive" = lib.mkDefault "-1";

            groupbar = {
              font_size = 12;
              font_family = "monospace";
              font_weight_active = "ultraheavy";
              font_weight_inactive = "normal";
              indicator_height = 0;
              indicator_gap = 5;
              height = 22;
              gaps_in = 5;
              gaps_out = 0;
              text_color = lib.mkDefault (rgb colors.base05);
              text_color_inactive = "rgba(ffffff90)";
              "col.active" = lib.mkForce "rgba(3aff26bf)";
              "col.inactive" = lib.mkForce "rgba(f5274e80)";
              gradients = true;
              gradient_rounding = 0;
              gradient_round_only_edges = false;
            };
          };

          gestures = {
            workspace_swipe_invert = false;
            workspace_swipe_distance = 200;
            workspace_swipe_forever = true;
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            focus_on_activate = true;
            anr_missed_pings = 3;
            new_window_takes_over_fullscreen = 1;
            key_press_enables_dpms = true;
            mouse_move_enables_dpms = true;
          };

          # Special workspaces
          workspace = [
            "special:monitor, on-created-empty: ${kitty} ${btop}"
          ];

          # Omarchy window rules + personal rules
          windowrule = [
            "suppressevent maximize, class:.*"
            "opacity 0.97 0.9, class:.*"
            "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
            "scrolltouchpad 1.5, class:(Alacritty|kitty)"
            "scrolltouchpad 0.2, class:com.mitchell.ghostty"
            # Personal window rules
            "float, title:^(MainPicker)$"
            "float, title:^(Sign in to Security Device)$"
            "workspace 10,title:^(app.v2.gather.town is sharing)(.*)$"
            "float,title:^()$,class:^(dev.zed.Zed)$"
            "opacity 0.85,class:(dev.zed.Zed)"
            "group,class:signal"
            "group,class:Slack"
            "float,class:^(dropdown)$"
            "size 800 400,class:^(dropdown)$"
            "center,class:^(dropdown)$"
            "animation slide,class:^(dropdown)$"
          ];

          # Tiling bindings (Omarchy + personal vim keys)
          bind = [
            # Close windows
            "$mainMod, Q, killactive,"
            # Control tiling
            "$mainMod, S, togglesplit,"
            "$mainMod, P, pseudo,"
            "$mainMod, F, togglefloating,"
            ",F11,fullscreen"
            "$mainMod CTRL, F, fullscreenstate, 0 2"
            "$mainMod ALT, F, fullscreen, 1"
            # Applications
            "$mainMod, Return, exec, ${kitty}"
            "$mainMod, E, exec, ${thunar}"
            "$mainMod, SPACE, exec, ${fuzzel}"
            "$mainMod, Y, exec, oath 19125157"
            "$mainMod, V, exec, ${cliphist} list | ${fuzzel} --dmenu | ${cliphist} decode | ${wl-copy}"
            # Web apps
            "$mainMod SHIFT, A, exec, launch-webapp https://chatgpt.com"
            # Move focus with vim keys
            "$mainMod, h, movefocus, l"
            "$mainMod, L, exec, loginctl lock-session && ${hyprlock}"
            "$mainMod, k, movefocus, u"
            "$mainMod, j, movefocus, d"
            # Move focus with arrow keys
            "$mainMod, LEFT, movefocus, l"
            "$mainMod, RIGHT, movefocus, r"
            "$mainMod, UP, movefocus, u"
            "$mainMod, DOWN, movefocus, d"
            # Move/swap windows with vim keys
            "$mainMod SHIFT, h, movewindoworgroup, l"
            "$mainMod SHIFT, l, movewindoworgroup, r"
            "$mainMod SHIFT, k, movewindoworgroup, u"
            "$mainMod SHIFT, j, movewindoworgroup, d"
            # Resize with vim keys
            "$mainMod CTRL, h, resizeactive, -60 0"
            "$mainMod CTRL, l, resizeactive, 60 0"
            "$mainMod CTRL, k, resizeactive, 0 -60"
            "$mainMod CTRL, j, resizeactive, 0 60"
            # Switch workspaces with numbers
            "$mainMod, 1, workspace, 1"
            "$mainMod, 2, workspace, 2"
            "$mainMod, 3, workspace, 3"
            "$mainMod, 4, workspace, 4"
            "$mainMod, 5, workspace, 5"
            "$mainMod, 6, workspace, 6"
            "$mainMod, 7, workspace, 7"
            "$mainMod, 8, workspace, 8"
            "$mainMod, 9, workspace, 9"
            "$mainMod, 0, workspace, 10"
            # Move window silently to workspace
            "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
            "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
            "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
            "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
            "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
            "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
            "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
            "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
            "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
            "$mainMod SHIFT, 0, movetoworkspacesilent, 10"
            # Special workspaces
            "$mainMod, B, togglespecialworkspace, browser"
            "$mainMod, Z, togglespecialworkspace, spotify"
            "$mainMod, C, togglespecialworkspace, chat"
            "$mainMod, M, togglespecialworkspace, monitor"
            "$mainMod, O, togglespecialworkspace, obs"
            # TAB between workspaces
            "$mainMod, TAB, workspace, previous"
            "$mainMod SHIFT, TAB, workspace, e-1"
            "$mainMod CTRL, TAB, workspace, e+1"
            # Move workspaces to other monitors
            "$mainMod SHIFT ALT, LEFT, movecurrentworkspacetomonitor, l"
            "$mainMod SHIFT ALT, RIGHT, movecurrentworkspacetomonitor, r"
            # Swap windows with arrows
            "$mainMod SHIFT, LEFT, swapwindow, l"
            "$mainMod SHIFT, RIGHT, swapwindow, r"
            "$mainMod SHIFT, UP, swapwindow, u"
            "$mainMod SHIFT, DOWN, swapwindow, d"
            # Resize active window
            "$mainMod, minus, resizeactive, -100 0"
            "$mainMod, equal, resizeactive, 100 0"
            "$mainMod SHIFT, minus, resizeactive, 0 -100"
            "$mainMod SHIFT, equal, resizeactive, 0 100"
            # Scroll workspaces
            "$mainMod, mouse_down, workspace, e+1"
            "$mainMod, mouse_up, workspace, e-1"
            # Groups
            "$mainMod, G, togglegroup"
            "$mainMod ALT, G, moveoutofgroup"
            "$mainMod ALT, J, changegroupactive, f"
            "$mainMod ALT, K, changegroupactive, b"
            "$mainMod ALT, LEFT, moveintogroup, l"
            "$mainMod ALT, RIGHT, moveintogroup, r"
            "$mainMod ALT, UP, moveintogroup, u"
            "$mainMod ALT, DOWN, moveintogroup, d"
            "$mainMod ALT, TAB, changegroupactive, f"
            "$mainMod ALT SHIFT, TAB, changegroupactive, b"
            "$mainMod CTRL, LEFT, changegroupactive, b"
            "$mainMod CTRL, RIGHT, changegroupactive, f"
            "$mainMod ALT, mouse_down, changegroupactive, f"
            "$mainMod ALT, mouse_up, changegroupactive, b"
            # Group window by number
            "$mainMod ALT, 1, changegroupactive, 1"
            "$mainMod ALT, 2, changegroupactive, 2"
            "$mainMod ALT, 3, changegroupactive, 3"
            "$mainMod ALT, 4, changegroupactive, 4"
            "$mainMod ALT, 5, changegroupactive, 5"
            # Keyboard backlight
            "$mainMod, F3, exec, ${brightnessctl} -d *::kbd_backlight set +33%"
            "$mainMod, F2, exec, ${brightnessctl} -d *::kbd_backlight set 33%-"
            # Screenshot
            '', Print, exec, ${grim} -g "$(${slurp})" - | ${swappy} -f -''
          ];

          # ALT+TAB cycling
          bindr = [
            "ALT, TAB, cyclenext"
            "ALT SHIFT, TAB, cyclenext, prev"
            "ALT, TAB, bringactivetotop"
            "ALT SHIFT, TAB, bringactivetotop"
          ];

          # Media keys (repeat on hold)
          bindel = [
            ", XF86AudioRaiseVolume, exec, ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ", XF86AudioMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86AudioMicMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ", XF86MonBrightnessUp, exec, ${brightnessctl} set 5%+"
            ", XF86MonBrightnessDown, exec, ${brightnessctl} set 5%-"
          ];

          # Media playback (locked)
          bindl = [
            ", XF86AudioNext, exec, ${playerctl} next"
            ", XF86AudioPause, exec, ${playerctl} play-pause"
            ", XF86AudioPlay, exec, ${playerctl} play-pause"
            ", XF86AudioPrev, exec, ${playerctl} previous"
          ];

          # Mouse bindings
          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];

          exec-once = [
            "systemctl --user import-environment PATH && systemctl --user restart xdg-desktop-portal.service"
            "[workspace special:spotify silent] ${spotify}"
            "[workspace special:obs silent] ${obs} --startvirtualcam"
            "[workspace special:chat silent] ${slack}"
            "[workspace special:chat silent] ${signal}"
            "[workspace special:browser silent] ${brave}"
          ];
        };
    };
  };
}
