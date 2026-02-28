{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.themes;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  options = {
    modules.themes.enable = mkEnableOption "Enable Stylix theme" // {
      default = true;
    };
    modules.themes.theme = mkOption {
      type = types.either types.str types.path;
      description = "Path to base16 YAML theme file";
      example = ''
        ./assets/themes/grail.yaml
        $${pkgs.base16-schemes}/share/themes/material-darker.yaml
      '';
    };
    modules.themes.wallpaper = mkOption {
      type = types.path;
      description = "Path to wallpaper image";
      example = ''
        ./path/to/wallpaper.png
        ~/Wallpapers/Eric.png
      '';
    };
  };
  config = mkIf cfg.enable {
    stylix = {
      targets.gnome.enable = false;
      enable = true;
      fonts =
        let
          font = {
            package = pkgs.open-sans;
            name = "Open Sans";
          };
          mono = {
            package = pkgs.nerd-fonts.fira-mono;
            name = "FiraMono Nerd Font Mono";
          };
        in
        {
          serif = font;
          sansSerif = font;
          monospace = mono;
          emoji = {
            package = pkgs.nerd-fonts.symbols-only;
            name = "Symbols Nerd Font Mono";
          };

          sizes = {
            desktop = 14;
            popups = 10;
          };
        };
      image = cfg.wallpaper;
      base16Scheme = cfg.theme;
      opacity = {
        terminal = 0.65;
      };
    };
  };
}
