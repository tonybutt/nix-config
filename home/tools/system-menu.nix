{ pkgs, ... }:
let
  system-menu = pkgs.writeShellApplication {
    name = "system-menu";

    runtimeInputs = with pkgs; [
      fuzzel
    ];

    text = builtins.readFile ./system-menu;
  };
in
{
  home.packages = [ system-menu ];
}
