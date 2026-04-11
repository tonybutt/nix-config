{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.ssh;
in
{
  options = {
    modules.ssh.enable = mkEnableOption "Enable SSH client configuration" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    # Connection multiplexing needs a socket directory
    home.file.".ssh/sockets/.keep".text = "";

    programs.ssh = {
      enable = true;
      # HM default values are deprecated and will be removed; manage everything explicitly
      enableDefaultConfig = false;

      extraOptionOverrides = {
        # AEAD ciphers first (ChaCha20 is constant-time without AES-NI, GCM is hw-accelerated)
        # CTR modes for older server compat; no CBC (padding oracle attacks)
        Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr";
        # Post-quantum hybrid KEM first (harvest-now-decrypt-later defense)
        # curve25519 as modern default; DH group16/18 (4096/8192-bit) for compat
        # No NIST curves, no group14 (2048-bit, increasingly weak)
        KexAlgorithms = "sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256";
        # Encrypt-then-MAC only; non-ETM variants have known theoretical weaknesses
        # No SHA-1 MACs
        MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com";
        # Accept ed25519 and RSA-SHA2 host keys only (cert variants first for SSH CA environments)
        # No ECDSA (NIST curve concerns), no ssh-rsa (SHA-1)
        HostKeyAlgorithms = "sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256";
        # Restrict CA signature algorithms to modern options if SSH certificates are ever used
        CASignatureAlgorithms = "sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256";
        # Only offer explicitly configured keys, never try all keys in agent
        IdentitiesOnly = "yes";
        # X11 forwarding is a large attack surface; disabled globally
        ForwardX11 = "no";
        ForwardX11Trusted = "no";
        # Verify server IP hasn't changed since last connection (DNS spoofing protection)
        CheckHostIP = "yes";
      };

      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = [
            "~/.ssh/id_ed25519_sk"
            "~/.ssh/id_ed25519"
          ];
          # Git expects SSH to exit after the protocol exchange; ControlMaster keeps it alive
          controlMaster = "no";
          extraOptions = {
            PubkeyAcceptedAlgorithms = "sk-ssh-ed25519@openssh.com,ssh-ed25519";
            PreferredAuthentications = "publickey";
          };
        };
        # Global defaults applied to all hosts
        "*" = {
          # Only allow FIDO2 ed25519-sk keys by default — YubiKey or nothing
          # Per-host matchBlocks can override this (e.g. github.com also allows ssh-ed25519)
          extraOptions = {
            PubkeyAcceptedAlgorithms = "sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com";
          };
          # Hash hostnames in known_hosts so a compromised file doesn't map your infrastructure (CIS benchmark)
          hashKnownHosts = true;
          # Add keys to agent but require confirmation on each use; pairs well with FIDO2 touch
          addKeysToAgent = "confirm";
          # Detect dead connections: keepalive every 5 min, disconnect after 3 misses (15 min total)
          serverAliveInterval = 300;
          serverAliveCountMax = 3;
          # Compression adds BREACH-like attack surface for negligible gain on modern networks
          compression = false;
          # Agent forwarding exposes keys to the remote host; use ProxyJump instead
          forwardAgent = false;
          # Reuse TCP connections to the same host — faster subsequent sessions
          controlMaster = "auto";
          controlPath = "~/.ssh/sockets/%r@%h-%p";
          controlPersist = "10m";
        };
        mantra = {
          hostname = "mantra.lan";
          user = "anthony";
          identityFile = [ "~/.ssh/id_ed25519_sk" ];
        };
        lapnix = {
          hostname = "lapnix.lan";
          user = "anthony";
          identityFile = [ "~/.ssh/id_ed25519_sk" ];
        };
        atlas = {
          hostname = "atlas.lan";
          user = "anthony";
          identityFile = [ "~/.ssh/id_ed25519_sk" ];
        };
      };
    };
  };
}
