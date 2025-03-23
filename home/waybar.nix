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
          "battery"
          "clock"
        ];
        "hyprland/workspaces" = {
          show-special = true;
        };
      };
    };
    style = lib.mkAfter (builtins.readFile ./waybar.css);
  };
}
