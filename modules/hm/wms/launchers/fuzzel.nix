{ lib, ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = lib.mkForce "FiraMono Nerd Font Mono:size=18";
        width = 50;
        lines = 15;
        horizontal-pad = 24;
        vertical-pad = 16;
        inner-pad = 8;
      };
    };
  };
}
