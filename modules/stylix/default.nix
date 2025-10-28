{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.secondfront.themes;
  inherit (lib) mkIf mkEnableOption;
in
{
  options = {
    secondfront.themes.enable = mkEnableOption "Enable Stylix theme" // {
      default = true;
    };
    secondfront.themes.darkOxide.enable = mkEnableOption "Enable Dark Oxide theme" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    stylix = {
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
      image = ./assets/walls/wallpaper.png;
      base16Scheme = ./assets/themes/dark_oxide.yaml;
      opacity = {
        terminal = 0.65;
      };
    };
  };
}
