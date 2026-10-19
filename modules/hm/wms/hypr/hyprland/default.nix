{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkEnableOption;
in
{
  imports = [
    ./autostart.nix
    ./bindings.nix
    ./look-and-feel.nix
    ./monitors.nix
    ./rules.nix
  ];

  options.modules.hyprland.enable = mkEnableOption "Enable hyprland window Manager" // {
    default = true;
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      # Hyprland 0.56+ resolves only ~/.config/hypr/hyprland.lua; the
      # hyprlang main config is gone upstream, so generate the Lua DSL.
      configType = "lua";
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      systemd = {
        enable = true;
        variables = [ "--all" ];
      };
      settings = {
        env = [
          # Cursor size
          {
            _args = [
              "XCURSOR_SIZE"
              "24"
            ];
          }
          {
            _args = [
              "HYPRCURSOR_SIZE"
              "24"
            ];
          }
          # Force all apps to use Wayland
          {
            _args = [
              "GDK_BACKEND"
              "wayland,x11,*"
            ];
          }
          {
            _args = [
              "QT_QPA_PLATFORM"
              "wayland;xcb"
            ];
          }
          {
            _args = [
              "QT_STYLE_OVERRIDE"
              "kvantum"
            ];
          }
          {
            _args = [
              "SDL_VIDEODRIVER"
              "wayland"
            ];
          }
          {
            _args = [
              "MOZ_ENABLE_WAYLAND"
              "1"
            ];
          }
          {
            _args = [
              "ELECTRON_OZONE_PLATFORM_HINT"
              "wayland"
            ];
          }
          {
            _args = [
              "OZONE_PLATFORM"
              "wayland"
            ];
          }
          {
            _args = [
              "XDG_SESSION_TYPE"
              "wayland"
            ];
          }
          # Screen sharing support
          {
            _args = [
              "XDG_CURRENT_DESKTOP"
              "Hyprland"
            ];
          }
          {
            _args = [
              "XDG_SESSION_DESKTOP"
              "Hyprland"
            ];
          }
          # XCompose file
          {
            _args = [
              "XCOMPOSEFILE"
              "~/.XCompose"
            ];
          }
        ];

        config = {
          xwayland = {
            force_zero_scaling = false;
          };

          cursor = {
            no_hardware_cursors = true;
            hide_on_key_press = true;
          };

          ecosystem = {
            no_update_news = true;
          };

          debug = {
            disable_logs = false;
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

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            focus_on_activate = true;
            anr_missed_pings = 3;
            on_focus_under_fullscreen = 1;
            key_press_enables_dpms = true;
            mouse_move_enables_dpms = true;
          };
        };

        gesture = [
          {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          }
        ];
      };
    };
  };
}
