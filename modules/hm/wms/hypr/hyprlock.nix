{ config, lib, ... }:
with lib;
let
  cfg = config.secondfront.hyprland.hyprlock;
in
{
  options = {
    secondfront.hyprland.hyprlock.enable = mkEnableOption "Enable hyprlock" // {
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
        };

        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "250, 60";
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(0, 0, 0, 0.5)";
            font_color = "rgb(200, 200, 200)";
            fade_on_empty = false;
            font_family = "Fira Mono";
            placeholder_text = ''<i><span foreground="##cdd6f4">Input Password...</span></i>'';
            hide_input = false;
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];
        label = [
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%-I:%M%p")"'';
            color = "rgba(255, 255, 255, 0.6)";
            font_size = 120;
            font_family = "Fira Mono";
            position = "0, -300";
            halign = "center";
            valign = "top";
          }
          {
            monitor = "";
            text = "Hi there, $USER";
            text_align = "center"; # center/right or any value for default left. multi-line text alignment inside label container
            color = "rgba(200, 200, 200, 1.0)";
            font_size = 25;
            font_family = "Fira Code";
            rotate = 0; # degrees, counter-clockwise

            position = "0, 80";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
