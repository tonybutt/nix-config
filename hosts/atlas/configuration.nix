{
  pkgs,
  lib,
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

  # Build aarch64 closures (Raspberry Pi kiosk image) via QEMU emulation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  modules = {
    hostName = "atlas";
    grub = false;
    laptop = true;
    sops.enable = true;
    ssh.enable = true;
    peripherals = {
      enable = true;
      obs.enable = true;
      scarlettRite.enable = true;
      openrazer.enable = true;
    };
  };

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.font-awesome
    pkgs.material-icons
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  hardware.graphics.enable32Bit = true;

  sops.secrets.notifier-slack-token.owner = "anthony";

  # The Navi 33 in the expansion bay has no connected display outputs — every
  # connector belongs to the Phoenix1 iGPU — so it is a pure offload device.
  # Default all GL and Vulkan clients to it, which hands the APU's shared power
  # budget and DDR5 bandwidth back to the CPU cores for compiles. Hyprland
  # itself is unaffected and keeps rendering on the iGPU that owns the displays.
  #
  # Both variables are required: DRI_PRIME only steers GL/EGL, Vulkan ignores it.
  # Addressed by PCI path and vendor:device rather than DRI_PRIME=1, since the
  # positional index is not stable across boots.
  environment.sessionVariables = {
    DRI_PRIME = "pci-0000_03_00_0";
    MESA_VK_DEVICE_SELECT = "1002:7480";
  };

  # Merges with the on-the-go specialisation defined in modules/nixos/laptop.nix
  # rather than replacing it. On battery the dGPU is not worth its idle draw, so
  # hand rendering back to the iGPU.
  specialisation.on-the-go.configuration = {
    environment.sessionVariables = {
      DRI_PRIME = lib.mkForce "pci-0000_c5_00_0";
      MESA_VK_DEVICE_SELECT = lib.mkForce "1002:15bf";
    };
  };

  services.fwupd.enable = true;

  hardware.keyboard.zsa.enable = true;

  system.stateVersion = "25.05";
}
