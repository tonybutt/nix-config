{ pkgs, ... }:
let
  mp4-to-gif = pkgs.writeShellApplication {
    name = "mp4-to-gif";

    runtimeInputs = with pkgs; [
      ffmpeg
    ];

    text = builtins.readFile ./mp4-to-gif;
  };
in
{
  home.packages = [ mp4-to-gif ];
}
