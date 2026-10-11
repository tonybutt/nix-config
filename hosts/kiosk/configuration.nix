{
  pkgs,
  lib,
  user,
  inputs,
  ...
}:
let
  # The Guild Hall kiosk binary is not part of this closure: the task repo
  # deploys it as its own deploy-rs profile (`nix run .#deploy-kiosk` there),
  # so app releases never need a nix-config change. Deploy that profile
  # before this host, or cage has nothing to run and the switch rolls back.
  # kioskProgram = "/nix/var/nix/profiles/guild-hall-kiosk/bin/kiosk";
  apiBaseUrl = "https://${apiHost}";
  # LAN-only: public DNS for *.abutt.dev points at the Cloudflare tunnel,
  # which does not route this host; the gems gateway VIP serves it on :443
  apiHost = "task.abutt.dev";
  gemsGatewayIp = "192.168.86.10";

  # Dev mode: cage runs whatever the task repo's `nix run .#kiosk-dev` last
  # published to kioskDevDir and relaunches it on every publish, so the
  # deploy user can iterate on the kiosk user's screen without sudo
  kioskDevDir = "/srv/guild-hall-dev";
  kioskDevSupervisor = pkgs.writeShellApplication {
    name = "guild-hall-kiosk-dev-supervisor";
    runtimeInputs = [ pkgs.inotify-tools ];
    text = ''
      dev_dir=${kioskDevDir}
      while true; do
        pid=""
        if [ -x "$dev_dir/run" ]; then
          "$dev_dir/run" &
          pid=$!
        fi
        inotifywait -qq -e moved_to -e close_write --include '/run$' "$dev_dir"
        if [ -n "$pid" ]; then
          kill "$pid" 2>/dev/null || true
          wait "$pid" || true
        fi
      done
    '';
  };
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

  # 8G and no swap thrashes the page cache under on-device Rust builds
  # (kiosk-dev); compressed in-RAM swap gives idle pages somewhere to go
  zramSwap.enable = true;

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
    # Dev mode. Switch to kioskProgram only once `nix run .#deploy-kiosk`
    # has created the profile: a cage with nothing to run fails, and a failed
    # cage makes deploy-rs roll the whole switch back
    program = lib.getExe kioskDevSupervisor;
    # program = kioskProgram;
  };

  # Read by the kiosk at startup; per-device values live here, the app's
  # defaults live in the task repo (desktop/kiosk.example.toml)
  environment.etc."guild-hall/kiosk.toml".text = ''
    api_base_url = "${apiBaseUrl}"
  '';
  networking.hosts.${gemsGatewayIp} = [ apiHost ];

  # Pairing writes the device token to /var/lib/guild-hall-kiosk (the kiosk
  # prefers it over its working directory whenever it exists); kioskDevDir is
  # written by the deploy user and read by the kiosk user
  systemd.tmpfiles.rules = [
    "d /var/lib/guild-hall-kiosk 0700 kiosk kiosk -"
    "d ${kioskDevDir} 2750 ${user.username} kiosk -"
  ];

  # The cage module leaves its session alone on switch (restartIfChanged =
  # false), so a changed cage-tty1 is stopped and never started again; the
  # kiosk session holds nothing worth preserving, so restart it instead
  systemd.services."cage-tty1".restartIfChanged = lib.mkForce true;
  # cage owns tty1 and Conflicts= its getty; a switch that pulls the getty
  # in (it happened on a networking.hosts change) silently stops the kiosk
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

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

  # The deploy user has no password, so give it just enough to bounce the
  # kiosk session; same canonical-store-path matching as modules/nixos/ssh
  security.sudo.extraRules = [
    {
      users = [ user.username ];
      commands =
        map
          (verb: {
            command = "/nix/store/*/bin/systemctl ${verb} cage-tty1.service";
            options = [ "NOPASSWD" ];
          })
          [
            "start"
            "stop"
            "restart"
          ];
    }
  ];

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
