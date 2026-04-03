{
  pkgs,
  lib,
  user,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos
  ];

  modules = {
    hostName = "mantra";
    grub = true;
    laptop = false;
    virtualization.vms.enable = true;
    sops.enable = true;
    peripherals = {
      enable = true;
      obs.enable = true;
    };
  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Mantra is a desktop on ethernet — disable wireless from shared modules
  networking.wireless.enable = lib.mkForce false;

  # GPU — RX 6900 XT (RDNA 2, RADV is default)
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    cascadia-code
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
  ];

  # SSH server — hardened, yubikey-sk only
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

  # GitHub Actions runners (repo-level)
  services.github-runners = builtins.listToAttrs (
    map
      (n: {
        name = "mantra-jcu-${toString n}";
        value = {
          enable = true;
          url = "https://github.com/tonybutt/jcu-site";
          tokenFile = config.sops.secrets.github-runner-token.path;
          extraLabels = [ "nix" ];
          replace = true;
          extraPackages = with pkgs; [
            git
            nix
          ];
        };
      })
      [
        1
        2
        3
        4
      ]
  );

  system.stateVersion = "24.05";
}
