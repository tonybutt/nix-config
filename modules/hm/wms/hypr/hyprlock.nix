{ config, lib, ... }:
with lib;
let
  cfg = config.modules.hyprlock;
  colors = config.lib.stylix.colors;
in
{
  options.modules.hyprlock = {
    enable = mkEnableOption "Enable hyprlock" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 0;
          hide_cursor = true;
          ignore_empty_input = true;
        };

        background = [
          {
            monitor = "";
            path = config.modules.hyprpaper.wallpaper;
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "650, 100";
            position = "0, 0";
            halign = "center";
            valign = "center";

            outline_thickness = 4;
            rounding = 0;

            outer_color = "rgb(${colors.base0D})";
            inner_color = "rgb(${colors.base00})";
            font_color = "rgb(${colors.base05})";
            check_color = "rgb(${colors.base0B})";
            fail_color = "rgb(${colors.base08})";

            font_family = "JetBrainsMono Nerd Font";
            placeholder_text = "Enter Password";
            fail_text = "<i>$FAIL ($ATTEMPTS)</i>";

            fade_on_empty = false;
            shadow_passes = 0;
          }
        ];

        label = [
          # Time
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%H:%M")"'';
            color = "rgb(${colors.base05})";
            font_size = 120;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 200";
            halign = "center";
            valign = "center";
          }
          # Date
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%A, %d %B")"'';
            color = "rgb(${colors.base04})";
            font_size = 24;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 100";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
