{ pkgs, ... }:
let
  launch-webapp = pkgs.writeShellApplication {
    name = "launch-webapp";

    runtimeInputs = with pkgs; [
      brave
    ];

    text = builtins.readFile ./launch-webapp;
  };
in
{
  home.packages = [ launch-webapp ];
}
