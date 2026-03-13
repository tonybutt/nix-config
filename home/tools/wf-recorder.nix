{ pkgs, ... }:
let
  wf-recorder-toggle = pkgs.writeShellApplication {
    name = "wf-recorder-toggle";

    runtimeInputs = with pkgs; [
      wf-recorder
      procps
      libnotify
      jq
      hyprland
    ];

    text = builtins.readFile ./wf-recorder;
  };
in
{
  home.packages = [ wf-recorder-toggle ];
}
