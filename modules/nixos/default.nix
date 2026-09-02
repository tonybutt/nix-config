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
    ./browser.nix
    ./packages.nix
    ./wms
    ./peripherals
    ./users
    ./virtualizations
    ./laptop.nix
    ./ssh
    ./sops
    ./endpoint-verification
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
    modules.laptop = mkOption {
      type = types.bool;
      default = false;
      description = "Enable laptop-specific configuration (lid switch handling, clamshell mode).";
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
      loader.systemd-boot = mkIf (!cfg.grub) {
        enable = true;
        configurationLimit = 3;
      };
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

    # Google Endpoint Verification reads the device serial as the logged-in
    # user; default is 0400 root:root. Grant wheel read instead of sudo/cat.
    systemd.tmpfiles.rules = [
      "z /sys/class/dmi/id/product_serial 0440 root wheel -"
    ];

    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = "1h";
      HibernateOnACPower = "no";
    };

    # Restarting the audio stack mid-session races WirePlumber's device probe:
    # cards re-register under a ".2"-suffixed name and get parked on the "Off"
    # profile, killing microphones until reboot. Let pipewire updates land on
    # the next boot instead of restarting during a switch.
    systemd.user.services = {
      pipewire.restartIfChanged = false;
      pipewire-pulse.restartIfChanged = false;
      wireplumber.restartIfChanged = false;
    };

    services = {
      upower.enable = true;
      devmon.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
      tumbler.enable = true;
      printing = {
        enable = true;
        drivers = with pkgs; [
          gutenprint
          brlaser
          brgenml1lpr
          brgenml1cupswrapper
        ];
      };
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      blueman.enable = true;
      pcscd.enable = true;
      gnome.gnome-keyring.enable = true;

      # Tailscale client pointed at the company Headscale server; operator
      # lets trayscale/CLI control the daemon without sudo. Authenticate
      # once per host with `ts-login` (zsh alias). extraUpFlags also apply
      # automatically if authKeyFile is ever set for preauth-key joins.
      tailscale = {
        enable = true;
        extraSetFlags = [ "--operator=${user.username}" ];
        extraUpFlags = [ "--login-server=https://headscale.tiberius.com" ];
      };

      logind.settings.Login = {
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
