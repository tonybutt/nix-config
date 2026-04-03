{
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

  # SSH server — hardened, LAN only, yubikey-sk only
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AuthenticationMethods = "publickey";
    };
  };
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --dport 22 -s 192.168.86.0/24 -j nixos-fw-accept
    iptables -A nixos-fw -p tcp --dport 22 -j nixos-fw-drop
  '';
  users.users.${user.username}.openssh.authorizedKeys.keys = [
    "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO9ZH1VvOc2+1tAkzQzNwhyT+LT6wCBmt9gP2yeH8g+oAAAABHNzaDo= abutt@tiberius.com"
    "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKoZU8AWvPjbgJfQXA3Kl6Ep9PzO6tGdN3GP4BRcTitOAAAABHNzaDo= anthony@abutt.io"
  ];
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
