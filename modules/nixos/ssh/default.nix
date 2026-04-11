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
      # Only serve ed25519 host keys — no RSA, no ECDSA
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        # Authentication
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AuthenticationMethods = "publickey";
        # AEAD ciphers first; no CBC (padding oracle attacks)
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];
        # Post-quantum hybrid KEM first; no NIST curves, no group14
        KexAlgorithms = [
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "diffie-hellman-group-exchange-sha256"
        ];
        # Encrypt-then-MAC only; no SHA-1
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
        # Log key fingerprints for audit trail
        LogLevel = "VERBOSE";
        # Brute-force mitigation
        LoginGraceTime = 30;
        MaxAuthTries = 3;
        MaxSessions = 3;
        # Detect dead connections: keepalive every 5 min, drop after 3 misses
        ClientAliveInterval = 300;
        ClientAliveCountMax = 3;
        # Disable unused features — use ProxyJump instead of agent forwarding
        X11Forwarding = false;
        AllowAgentForwarding = false;
        AllowTcpForwarding = false;
        AllowStreamLocalForwarding = false;
        PermitTunnel = false;
        # Don't leak system info
        PrintMotd = false;
        PermitEmptyPasswords = false;
      };
    };
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 22 -s ${cfg.lanSubnet} -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 22 -j nixos-fw-drop
    '';
    # Passwordless sudo for deploy-rs activation
    security.sudo.extraRules = [
      {
        users = [ user.username ];
        commands = [
          {
            command = "/nix/store/*/activate-rs";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/nix/store/*/switch-to-configuration";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-env";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    users.users.${user.username}.openssh.authorizedKeys.keys = [
      "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO9ZH1VvOc2+1tAkzQzNwhyT+LT6wCBmt9gP2yeH8g+oAAAABHNzaDo= abutt@tiberius.com"
      "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKoZU8AWvPjbgJfQXA3Kl6Ep9PzO6tGdN3GP4BRcTitOAAAABHNzaDo= anthony@abutt.io"
    ];
  };
}
