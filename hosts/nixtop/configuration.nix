{
  pkgs,
  lib,
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
  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.font-awesome
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.printing.enable = true;
  virtualisation.libvirtd.qemu.runAsRoot = lib.mkForce true;
  virtualisation.libvirtd.qemu.verbatimConfig = lib.mkForce "";
  users.groups.libvirtd.members = [ "anthony" ];
  system.stateVersion = "24.05";
}
