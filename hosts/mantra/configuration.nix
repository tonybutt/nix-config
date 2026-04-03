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
  users.users.${user.username}.openssh.authorizedKeys.keys = [
    # ed25519-sk yubikey key — replace with your actual public key
    "sk-ssh-ed25519@openssh.com REPLACE_WITH_YOUR_YUBIKEY_SK_PUBKEY"
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
