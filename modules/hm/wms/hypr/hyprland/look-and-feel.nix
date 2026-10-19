{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib) mkIf;
  inherit (config.lib.stylix) colors;
  isDark = config.modules.themes.polarity == "dark";
  rgb = color: "rgb(${color})";
  activeGradient = {
    colors = [
      (rgb colors.base0B)
      (rgb colors.base0A)
    ];
    angle = 45;
  };
  inactiveGradient = rgb colors.base00;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      # Omarchy look and feel
      # String "col.*" keys intentionally mirror stylix's, so mkForce
      # overrides its target values instead of adding parallel keys
      config = {
        general = {
          "col.active_border" = lib.mkForce activeGradient;
          "col.inactive_border" = lib.mkForce inactiveGradient;
          gaps_in = 3;
          gaps_out = 6;
          border_size = 2;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 6;

          shadow = {
            enabled = false;
            range = 2;
            render_power = 3;
          };

          blur = {
            enabled = true;
            size = 6;
            passes = 3;
            special = false;
            brightness = 0.80;
            contrast = 0.90;
            new_optimizations = true;
            ignore_opacity = true;
          };
        };

        animations = {
          enabled = true;
        };

        dwindle = {
          preserve_split = true;
          force_split = 2; # Always split on the right
        };

        master = {
          new_status = "master";
        };

        group = {
          "col.border_active" = lib.mkForce activeGradient;
          "col.border_inactive" = lib.mkForce inactiveGradient;
          "col.border_locked_active" = lib.mkForce activeGradient;
          "col.border_locked_inactive" = lib.mkForce inactiveGradient;

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
            text_color = lib.mkForce (rgb (if isDark then colors.base00 else colors.base07));
            text_color_inactive = lib.mkForce (rgb (if isDark then colors.base04 else colors.base02));
            "col.active" = lib.mkForce (rgb colors.base0B);
            "col.inactive" = lib.mkForce (rgb (if isDark then colors.base02 else colors.base05));
            gradients = true;
            gradient_rounding = 0;
            gradient_round_only_edges = false;
          };
        };
      };

      # Omarchy animation curves
      curve = [
        {
          _args = [
            "easeOutQuint"
            {
              type = "bezier";
              points = [
                [
                  0.23
                  1
                ]
                [
                  0.32
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "easeInOutCubic"
            {
              type = "bezier";
              points = [
                [
                  0.65
                  0.05
                ]
                [
                  0.36
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "linear"
            {
              type = "bezier";
              points = [
                [
                  0
                  0
                ]
                [
                  1
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "almostLinear"
            {
              type = "bezier";
              points = [
                [
                  0.5
                  0.5
                ]
                [
                  0.75
                  1.0
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "quick"
            {
              type = "bezier";
              points = [
                [
                  0.15
                  0
                ]
                [
                  0.1
                  1
                ]
              ];
            }
          ];
        }
      ];

      # Omarchy animations
      animation = [
        {
          leaf = "global";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 5.39;
          bezier = "easeOutQuint";
        }
        {
          leaf = "windows";
          enabled = true;
          speed = 4.79;
          bezier = "easeOutQuint";
        }
        {
          leaf = "windowsIn";
          enabled = true;
          speed = 4.1;
          bezier = "easeOutQuint";
          style = "popin 87%";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 1.49;
          bezier = "linear";
          style = "popin 87%";
        }
        {
          leaf = "fadeIn";
          enabled = true;
          speed = 1.73;
          bezier = "almostLinear";
        }
        {
          leaf = "fadeOut";
          enabled = true;
          speed = 1.46;
          bezier = "almostLinear";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 3.03;
          bezier = "quick";
        }
        {
          leaf = "layers";
          enabled = true;
          speed = 3.81;
          bezier = "easeOutQuint";
        }
        {
          leaf = "layersIn";
          enabled = true;
          speed = 4;
          bezier = "easeOutQuint";
          style = "fade";
        }
        {
          leaf = "layersOut";
          enabled = true;
          speed = 1.5;
          bezier = "linear";
          style = "fade";
        }
        {
          leaf = "fadeLayersIn";
          enabled = true;
          speed = 1.79;
          bezier = "almostLinear";
        }
        {
          leaf = "fadeLayersOut";
          enabled = true;
          speed = 1.39;
          bezier = "almostLinear";
        }
        {
          leaf = "workspaces";
          enabled = false;
        }
      ];
    };
  };
}
