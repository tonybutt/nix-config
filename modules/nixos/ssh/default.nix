{
  config,
  lib,
  user,
  ...
}:
with lib;
let
  cfg = config.modules.ssh;
in
{
  options = {
    modules.ssh = {
      enable = mkEnableOption "Enable hardened SSH server";
      lanSubnet = mkOption {
        type = types.str;
        default = "192.168.86.0/24";
        description = "LAN subnet allowed to connect via SSH.";
      };
    };
  };
  config = mkIf cfg.enable {
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
      iptables -A nixos-fw -p tcp --dport 22 -s ${cfg.lanSubnet} -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 22 -j nixos-fw-drop
    '';
    users.users.${user.username}.openssh.authorizedKeys.keys = [
      "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO9ZH1VvOc2+1tAkzQzNwhyT+LT6wCBmt9gP2yeH8g+oAAAABHNzaDo= abutt@tiberius.com"
      "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKoZU8AWvPjbgJfQXA3Kl6Ep9PzO6tGdN3GP4BRcTitOAAAABHNzaDo= anthony@abutt.io"
    ];
  };
}
