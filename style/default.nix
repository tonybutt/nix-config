{ pkgs, ... }:
{
  stylix = {
    # Turn off styling of certain components
    # targets.hyprlock.enable = false;
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
    image = ./assets/wallpaper.png;
    base16Scheme = ./base16.yaml;
    opacity = {
      terminal = 0.65;
    };
  };
}
