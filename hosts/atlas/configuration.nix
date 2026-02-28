{
  pkgs,
  ...
}:
{
  imports = [
    # Generated automatically during install (uncommented by run-install)
    ./hardware-configuration.nix
    ./disks.nix
    ../../modules/nixos
  ];

  # Hibernation support — after install, get offset with:
  # sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
  boot.resumeDevice = "/dev/mapper/crypted";
  boot.kernelParams = [ "resume_offset=533760" ];

  modules = {
    hostName = "atlas";
    grub = false;
    laptop = true;
    peripherals = {
      enable = true;
      obs.enable = true;
      scarlettRite.enable = true;
    };
  };

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.font-awesome
    pkgs.material-icons
  ];

  services.fwupd.enable = true;

  hardware.keyboard.zsa.enable = true;

  system.stateVersion = "25.05";
}
