{
  lib,
  pkgs,
  user,
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

  hardware = {
    keyboard.zsa.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
          ControllerMode = "Dual";
          FastConnectable = true;
        };
        Policy = {
          AutoEnable = "true";
        };
        LE = {
          EnableAdvMonInterleaveScan = "true";
        };
      };
    };
  };

  nix = {
    channel.enable = false;
    settings = {
      trusted-users = [ user.username ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  system.stateVersion = "24.05";
}
