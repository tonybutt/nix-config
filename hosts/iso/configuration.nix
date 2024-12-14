{
  pkgs,
  modulesPath,
  system,
  lib,
  ...
}:
let
  run-install = pkgs.writeShellApplication {
    name = "run-install";
    runtimeInputs = with pkgs; [
      git
      disko
      rsync
    ];
    text = builtins.readFile ./run-install;
  };
in
{

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];
  nix = {
    channel.enable = false;
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };
  isoImage = {
    isoName = lib.mkForce "nixinstaller.iso";
    contents = [
      {
        source = ../../.;
        target = "cfg";
      }
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.hostPlatform = system;
  environment.systemPackages = with pkgs; [
    run-install
    disko
    vim
    git
  ];
}
