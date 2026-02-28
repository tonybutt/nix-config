{ pkgs }:
{
  final-fantasy = {
    scheme = ./modules/stylix/assets/themes/final_fantasy.yaml;
    wallpaper = ./modules/stylix/assets/walls/FF.png;
  };
  grail = {
    scheme = ./modules/stylix/assets/themes/grail.yaml;
    wallpaper = ./modules/stylix/assets/walls/Tiberius.png;
  };
  dark-oxide = {
    scheme = ./modules/stylix/assets/themes/dark_oxide.yaml;
    wallpaper = ./modules/stylix/assets/walls/Igris.png;
  };
  catppuccin-mocha = {
    scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    wallpaper = ./modules/stylix/assets/walls/catppuccin-mocha.png;
  };
  tokyo-night = {
    scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
    wallpaper = ./modules/stylix/assets/walls/tokyo-night.png;
  };
  hyprland-default = {
    scheme = ./modules/stylix/assets/themes/hyprland_default.yaml;
    wallpaper = ./modules/stylix/assets/walls/hyprland-default.png;
  };
}
