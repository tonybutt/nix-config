{
  config,
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

  # LAN-only: public DNS for *.abutt.dev points at the Cloudflare tunnel,
  # which does not route this host; the gems gateway VIP serves it on :443
  networking.hosts."192.168.86.10" = [ "task.abutt.dev" ];

  sops = {
    secrets = {
      forgejo-squire-read-token = { };
      notifier-slack-token.owner = "anthony";
    };

    templates."nix-daemon-private-modules.env".content =
      "GRAIL_FORGEJO_TOKEN=${config.sops.placeholder.forgejo-squire-read-token}";
  };

  # Docked, Hyprland composites on the Navi 33 in the expansion bay, so clients
  # rendered there hand their buffers to the compositor without a PCIe
  # crossing. A monitor on the module's rear USB-C port (DP-1 on the dGPU) is
  # scanned out by the Navi 33 directly; one on a chassis port hangs off the
  # Phoenix1 iGPU, which gets a copy of each finished frame for scanout. This
  # hands the APU's shared power budget and DDR5 bandwidth back to the CPU
  # cores for compiles. Any display on the module's port keeps the dGPU awake
  # regardless of these variables.
  #
  # Both PRIME variables are required: DRI_PRIME only steers GL/EGL, Vulkan
  # ignores it. Addressed by PCI path and vendor:device rather than
  # DRI_PRIME=1, since the positional index is not stable across boots. The
  # udev symlinks exist because AQ_DRM_DEVICES is colon-separated and the
  # by-path names contain colons.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:03:00.0", SYMLINK+="dri/dgpu"
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:c5:00.0", SYMLINK+="dri/igpu"
  '';

  environment.sessionVariables = {
    AQ_DRM_DEVICES = "/dev/dri/dgpu:/dev/dri/igpu";
    DRI_PRIME = "pci-0000_03_00_0";
    MESA_VK_DEVICE_SELECT = "1002:7480";
  };

  # Merges with the on-the-go specialisation defined in modules/nixos/laptop.nix
  # rather than replacing it. On battery the dGPU is not worth its idle draw, so
  # hand compositing and rendering back to the iGPU.
  specialisation.on-the-go.configuration = {
    environment.sessionVariables = {
      AQ_DRM_DEVICES = lib.mkForce "/dev/dri/igpu:/dev/dri/dgpu";
      DRI_PRIME = lib.mkForce "pci-0000_c5_00_0";
      MESA_VK_DEVICE_SELECT = lib.mkForce "1002:15bf";
    };
  };
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
    config.sops.templates."nix-daemon-private-modules.env".path;
  services.fwupd.enable = true;

  hardware.keyboard.zsa.enable = true;

  system.stateVersion = "25.05";
}
