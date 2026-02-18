{
  pkgs,
  config,
  lib,
  user,
  ...
}:
with lib;
let
  cfg = config.modules;
in
{
  imports = [
    ./packages.nix
    ./wms
    ./peripherals
    ./users
    ./virtualizations
    ../stylix
  ];
  options = {
    modules.enable = mkEnableOption "Enable NixOS modules" // {
      default = true;
    };
    modules.timeZone = mkOption {
      type = types.str;
      default = "America/New_York";
      description = "The system time zone.";
    };
    modules.hostName = mkOption {
      type = types.str;
      default = "";
      description = "The system hostname.";
    };
    modules.grub = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GRUB bootloader.";
    };
  };
  config = mkIf cfg.enable {
    nix = {
      channel.enable = false;
      settings = {
        trusted-users = [ user.username ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = [
          "https://hyprland.cachix.org"
          "https://claude-code.cachix.org"
        ];
        trusted-substituters = [
          "https://hyprland.cachix.org"
          "https://claude-code.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        ];
      };
    };

    boot = {
      loader.grub = mkIf cfg.grub {
        enable = true;
        efiSupport = true;
      };
      loader.systemd-boot.enable = mkIf (!cfg.grub) true;
      # Plymouth (Theming for booting screen and drive unlock screen)
      plymouth.enable = mkIf cfg.grub true;
      # Disable(quiet) most of the logging that happens during boot
      initrd = {
        verbose = false;
        systemd.enable = mkIf (!cfg.grub) true;
      };
      consoleLogLevel = 0;
      kernelParams = [
        "quiet"
        "udev.log_level=0"
      ];
    };

    networking = {
      hostName = cfg.hostName;
      firewall = {
        enable = true;
      };
      networkmanager.enable = true;
      wireless.enable = true;
    };

    hardware = {
      gpgSmartcards.enable = true;
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

    security = {
      sudo-rs = {
        enable = false;
        execWheelOnly = true;
      };
      sudo.enable = true;
      auditd.enable = true;
      audit.enable = true;
      rtkit.enable = true;
      pam.services = {
        hyprlock = { };
        greetd.enableGnomeKeyring = true;
      };
    };

    programs = {
      zsh.enable = true;
      ssh.startAgent = false;
      seahorse.enable = true;
      nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/home/${user.username}/nix-config";
      };

      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
        ];
      };
      xfconf.enable = true;
    };

    powerManagement.enable = true;

    systemd.sleep.extraConfig = ''
      HibernateDelaySec=1h
      HibernateOnACPower=no
    '';

    services = {
      upower.enable = true;
      devmon.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
      tumbler.enable = true;
      printing.enable = true;
      blueman.enable = true;
      pcscd.enable = true;
      gnome.gnome-keyring.enable = true;

      logind.settings.Login = {
        HandleLidSwitch = "suspend-then-hibernate";
        HandleLidSwitchDocked = "suspend-then-hibernate";
        HandleLidSwitchExternalPower = "suspend-then-hibernate";
        HandlePowerKey = "suspend-then-hibernate";
        HandlePowerKeyLongPress = "poweroff";
      };
    };

    time.timeZone = cfg.timeZone;
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
  };
}
