{ pkgs, ... }:
let
  themes = import ../../themes.nix { inherit pkgs; };
  themeList = builtins.concatStringsSep " " (builtins.attrNames themes);

  theme-switch = pkgs.writeShellApplication {
    name = "theme-switch";

    runtimeInputs = with pkgs; [
      nh
      hostname
      libnotify
    ];

    text = builtins.replaceStrings [ "@THEME_LIST@" ] [ themeList ] (builtins.readFile ./theme-switch);
  };

  # Generate a .desktop file for each theme
  themeDesktopEntries = builtins.mapAttrs (name: _: {
    name = "Theme: ${name}";
    exec = "${theme-switch}/bin/theme-switch ${name}";
    icon = "preferences-desktop-theme";
    comment = "Switch to the ${name} theme";
    categories = [ "Settings" ];
  }) themes;
in
{
  home.packages = [ theme-switch ];
  xdg.desktopEntries = themeDesktopEntries;
}
