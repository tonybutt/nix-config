{
  pkgs,
  config,
  hyprland,
  user,
  ...
}:
let
  hypr-pkgs = hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hypr-nixpkgs = hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
    };

    # Plymouth (Theming for booting screen and drive unlock screen)
    plymouth.enable = true;

    # Disable(quiet) most of the logging that happens during boot
    initrd = {
      verbose = false;
      systemd.enable = true;
    };

    consoleLogLevel = 0;

    kernelParams = [
      "quiet"
      "udev.log_level=0"
    ];

    kernelModules = [
      "v4l2loopback"
      "snd-aloop"
      "vfio-pci"
    ];

    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="OBS Camera"
      options snd_usb_audio vid=0x1235 pid=0x8212 device_setup=1
    '';
  };

  environment = {
    systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      qemu_kvm
      qemu
      xdg-utils
      seatd
      pavucontrol
      kitty
    ];
    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    twemoji-color-font
    font-awesome
    powerline-fonts
    powerline-symbols
    cascadia-code
  ];

  services = {
    devmon.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    tumbler.enable = true;
    printing.enable = true;
    blueman.enable = true;
    pcscd.enable = true;
    gnome.gnome-keyring.enable = true;
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs.hyprland}/share/wayland-sessions";
          user = user.name;
        };
      };
    };
    udev.extraRules = ''
      # Supporting VFIO
      SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"
    '';

    xserver = {
      enable = true;
      xkb.layout = "us";
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  programs = {
    zsh.enable = true;
    ssh.startAgent = false;
    seahorse.enable = true;

    hyprland = {
      enable = true;
      package = hypr-pkgs.hyprland;
      portalPackage = hypr-pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${user.name}/nix-config";
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    xfconf.enable = true;
  };

  security = {
    sudo.execWheelOnly = true;
    auditd.enable = true;
    audit.enable = true;
    rtkit.enable = true;
    pam.services = {
      hyprlock = { };
      greetd.enableGnomeKeyring = true;
    };
  };

  xdg.portal = {
    enable = true;
    config.common.default = [ "hyprland" ];
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      hypr-pkgs.xdg-desktop-portal-hyprland
    ];
  };

  hardware = {
    gpgSmartcards.enable = true;
    graphics = {
      enable = true;
      package = hypr-nixpkgs.mesa.drivers;
      package32 = hypr-nixpkgs.pkgsi686Linux.mesa.drivers;
      enable32Bit = true;
    };
    amdgpu.amdvlk = {
      enable = true;
      support32Bit.enable = true;
    };
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

  # Enable common container config files in /etc/containers
  virtualisation = {
    docker.enable = true;
    containers.enable = true;
    kvmgt.enable = true;
    spiceUSBRedirection.enable = true;

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;

        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };

        verbatimConfig = ''
          namespaces = []

          # Whether libvirt should dynamically change file ownership
          dynamic_ownership = 0
        '';
      };

      onBoot = "ignore";
      onShutdown = "shutdown";
    };
  };

  nix = {
    channel.enable = false;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.${user.name} = {
      isNormalUser = true;
      home = "/home/${user.name}";
      extraGroups = [
        "wheel"
        "networkmanager"
        "input"
        "docker"
        "libvirtd"
        "qemu-libvirtd"
        "kvm"
      ];
    };
  };

  networking = {
    hostName = "lapnix";
    firewall = {
      enable = true;
      trustedInterfaces = [
        "virbr0"
        "br0"
      ];
    };
    networkmanager.enable = true;
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
