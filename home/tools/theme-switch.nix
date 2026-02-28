{ pkgs, ... }:
let
  themes = import ../../themes.nix { inherit pkgs; };
  themeList = builtins.concatStringsSep " " (builtins.attrNames themes);

  theme-switch = pkgs.writeShellApplication {
    name = "theme-switch";

    runtimeInputs = with pkgs; [
      nh
      hostname
    ];

    text = builtins.replaceStrings [ "@THEME_LIST@" ] [ themeList ] (builtins.readFile ./theme-switch);
  };
in
{
  home.packages = [ theme-switch ];
}
