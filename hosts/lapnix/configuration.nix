{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos
  ];
  modules = {
    hostName = "lapnix";
    laptop = true;
    ssh.enable = true;
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

  # Build aarch64 closures (Raspberry Pi kiosk image) via QEMU emulation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Always on-the-go — no clamshell use, so always suspend on lid close
  services.logind.settings.Login = {
    HandleLidSwitchDocked = lib.mkForce "suspend-then-hibernate";
    HandleLidSwitchExternalPower = lib.mkForce "suspend-then-hibernate";
  };
  specialisation = lib.mkForce { };

  services.fwupd = {
    enable = true;
    # Disable EFI capsule updates to avoid 10+ second boot delay from "No updates to process"
    daemonSettings.DisableCapsuleUpdateOnDisk = true;
  };

  hardware.keyboard.zsa.enable = true;

  system.stateVersion = "24.05";
}
