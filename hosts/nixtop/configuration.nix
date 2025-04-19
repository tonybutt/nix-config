{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  modules = {
    hostName = "nixtop";
    peripherals = {
      enable = true;
      obs.enable = true;
      scarlettRite.enable = true;
    };
  };
  environment.systemPackages = [
    pkgs.firefox
    pkgs.brave
    pkgs.google-chrome
  ];
  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.font-awesome
  ];

  system.stateVersion = "24.05";
}
