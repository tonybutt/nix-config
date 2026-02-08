{
  pkgs,
  modulesPath,
  system,
  user,
  ...
}:
let
  hostname = builtins.getEnv "HOSTNAME";
  drive =
    let
      d = builtins.getEnv "DRIVE";
    in
    if d == "" then "/dev/nvme0n1" else d;
  run-install = pkgs.writeShellApplication {
    name = "run-install";
    runtimeInputs = with pkgs; [
      git
      disko
      nh
    ];
    text = (
      builtins.replaceStrings [ "__USER__" "__HOSTNAME__" "__DRIVE__" ] [ user.username hostname drive ] (
        builtins.readFile ./install.sh
      )
    );
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
  image = {
    fileName = "nixinstaller.iso";
  };
  isoImage = {
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
  networking.wireless.enable = true;
  environment.systemPackages = with pkgs; [
    run-install
    disko
    vim
    git
    toybox
  ];
}
