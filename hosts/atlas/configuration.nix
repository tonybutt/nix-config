{
  pkgs,
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

  modules = {
    hostName = "atlas";
    grub = false;
    laptop = true;
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
  users.users.anthony.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO9ZH1VvOc2+1tAkzQzNwhyT+LT6wCBmt9gP2yeH8g+oAAAABHNzaDo= abutt@tiberius.com"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKoZU8AWvPjbgJfQXA3Kl6Ep9PzO6tGdN3GP4BRcTitOAAAABHNzaDo= anthony@abutt.io"
  ];

  hardware.keyboard.zsa.enable = true;

  system.stateVersion = "25.05";
}
