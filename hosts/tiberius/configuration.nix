{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ../../modules/nixos
  ];
  modules = {
    hostName = "tiberius";
    grub = false;
    laptop = true;
    peripherals = {
      enable = true;
      obs.enable = true;
      scarlettRite.enable = true;
      openrazer.enable = true;
    };
  };
  boot.resumeDevice = "/dev/mapper/crypted";
  boot.kernelParams = [ "resume_offset=533760" ];

  services.fwupd.enable = true;
  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.font-awesome
    pkgs.material-icons
  ];
  hardware = {
    enableRedistributableFirmware = true;
    keyboard.zsa.enable = true;
  };

  system.stateVersion = "24.05";
}
