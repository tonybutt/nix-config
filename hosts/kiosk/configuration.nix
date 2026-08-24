{
  pkgs,
  lib,
  user,
  inputs,
  ...
}:
let
  # What the kiosk displays — change and `deploy .#kiosk` to update
  kioskUrl = "https://time.is";
in
{
  imports = [
    ../../modules/nixos/ssh
    ../../modules/nixos/users
    inputs.home-manager.nixosModules.home-manager
  ];

  # Just the zsh setup from the usual HM config (p10k needs stylix colors);
  # deliberately not the full home.nix desktop environment
  home-manager = {
    # No useGlobalPkgs: stylix's HM module sets nixpkgs.overlays, which
    # useGlobalPkgs will soon forbid
    useUserPackages = true;
    users.${user.username} = {
      imports = [
        inputs.stylix.homeModules.stylix
        ../../modules/stylix
        ../../modules/hm/shells
      ];
      home.stateVersion = "26.05";
      # This host deliberately follows nixos-raspberrypi's nixpkgs pin (cached
      # vendor kernel) while home-manager comes from the main flake, so a
      # release skew between the two is inherent, not an accident
      home.enableNixpkgsReleaseCheck = false;
      modules.themes = {
        theme = ../../modules/stylix/assets/themes/pokemon_starters.yaml;
        wallpaper = ../../modules/stylix/assets/walls/starters.png;
      };
    };
  };

  networking.hostName = "kiosk";

  # The sd-image base profile enables ZFS support; this host has no ZFS and
  # dropping it also removes the zfs tools from the closure
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # Generation-aware bootloader (rollbacks). The sd-image module used to set
  # this; without it the default regresses to single-generation "kernelboot"
  boot.loader.raspberry-pi.bootloader = "kernel";

  modules.ssh.enable = true;

  # modules/nixos/users sets zsh as default shell; kiosk skips the full
  # modules/nixos set that normally enables it
  programs.zsh.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # deploy-rs copies unsigned store paths over SSH; the connecting user
  # must be trusted by the target's nix daemon (same as other hosts)
  nix.settings.trusted-users = [ user.username ];

  # mDNS so the Pi is reachable as kiosk.local before it has a DNS entry
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${pkgs.chromium}/bin/chromium --kiosk --ozone-platform=wayland ${kioskUrl}";
  };
  # Chromium under cage ignores SIGTERM, so a graceful stop always ends in
  # systemd's fallback SIGKILL — which marks the unit failed and makes
  # deploy-rs roll back every switch. A kiosk session has no state worth a
  # graceful shutdown: kill it outright, which counts as a clean stop.
  systemd.services."cage-tty1".serviceConfig = {
    KillSignal = "SIGKILL";
    # systemd counts a SIGKILL death as failure unless declared expected
    SuccessExitStatus = "SIGKILL";
    TimeoutStopSec = 10;
  };

  # Home-manager's dconfSettings activation step (stylix GTK keys) needs a
  # dconf service; desktops get this from the full module set
  programs.dconf.enable = true;

  # Unprivileged session user for cage; not the SSH/deploy user
  users.users.kiosk = {
    isNormalUser = true;
    group = "kiosk";
  };
  users.groups.kiosk = { };

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    # EEPROM inspection/config for the NVMe boot-order step
    raspberrypi-eeprom
  ];

  system.stateVersion = "26.05";
}
