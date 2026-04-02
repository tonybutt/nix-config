# Mantra Runner Infrastructure Design

Turn mantra (Ryzen 9 5950X / 16c 32t / 92GB RAM / RX 6900 XT / ROG Crosshair VIII Hero) into a self-hosted GitHub Actions runner host for the `tonybutt` GitHub account, with sops-nix secret management, SSH access, and deploy-rs for remote rebuilds.

## 1. Refactor mantra to shared modules

Rewrite `hosts/mantra/configuration.nix` to follow the tiberius/atlas/lapnix pattern:

- Import `../../modules/nixos` and use the `modules.*` option interface
- Remove all duplicated boot, networking, security, programs, i18n config
- Keep mantra-specific overrides inline: VFIO/libvirtd, steam, docker, GPU passthrough config

### nixos-hardware modules

No Crosshair VIII Hero-specific module exists. Use common AMD modules:

```nix
hardwareModules = [
  nixos-hardware.nixosModules.common-cpu-amd
  nixos-hardware.nixosModules.common-cpu-amd-pstate
  nixos-hardware.nixosModules.common-gpu-amd
  nixos-hardware.nixosModules.common-pc
  nixos-hardware.nixosModules.common-pc-ssd
];
```

These provide: AMD microcode updates, pstate frequency scaling (active mode on kernel 6.3+), modesetting video driver + hardware.graphics + initrd amdgpu, standard desktop config, and SSD TRIM.

### hardware-configuration.nix

Does not exist yet. Gets generated at install time by `nixos-generate-config`. Create a placeholder that imports disko for now.

### Flake changes

Uncomment mantra in both `nixosConfigurations.hosts` and `homeConfigurations.hostDefaults`.

## 2. sops-nix

### Flake input

Add `sops-nix` as a flake input following nixpkgs.

### Key management

Use the SSH host ed25519 key that NixOS generates on first boot — no separate age key needed.

- sops-nix defaults to `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]`
- Convert host pubkey to age pubkey: `nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'`
- Store age public keys in `.sops.yaml` at repo root, mapping hosts to secrets they can decrypt

### Secrets file

`secrets/secrets.yaml` in repo root, encrypted with sops. Contains:

- `github-runner-token` — GitHub PAT for runner registration (scope: `admin:org` or user-level runner management)

### NixOS module

Create `modules/nixos/sops/default.nix`:

- Import sops-nix NixOS module
- Set `sops.defaultSopsFile` to `../../../secrets/secrets.yaml`
- Declare `sops.secrets.github-runner-token` with restrictive permissions

### Two-phase install workflow

1. Build ISO, install mantra
2. SSH in, grab host pubkey, convert to age pubkey
3. Add to `.sops.yaml`, run `sops secrets/secrets.yaml` to encrypt the GitHub PAT
4. `nixos-rebuild switch` (or `deploy .#mantra`) — secrets decrypt, runners come up

## 3. SSH + deploy-rs

### SSH server on mantra

Hardened OpenSSH config:

- `PasswordAuthentication = false`
- `KbdInteractiveAuthentication = false`
- `PermitRootLogin = "no"`
- `X11Forwarding = false`
- `AuthenticationMethods = "publickey"`
- Accept ed25519-sk yubikey key in `users.users.anthony.openssh.authorizedKeys.keys`

The user carries the same yubikey-sk key between atlas, lapnix, and any other machine — single key for all access.

### Network note

The shared `modules/nixos` enables `networking.wireless`. Mantra is a desktop on ethernet — override `networking.wireless.enable = false` in its configuration.

### deploy-rs

Add `deploy-rs` as a flake input.

Flake outputs define `deploy.nodes.mantra`:

- Hostname: mantra's local network address (static IP or hostname)
- SSH user: `anthony`
- Activation uses `sudo` for system profile switch
- Profile maps to `nixosConfigurations.mantra`
- `magicRollback = true` — auto-rolls back if activation fails and SSH drops

Workflow from atlas/lapnix:

1. Edit nix-config
2. `deploy .#mantra` — builds closure locally (or on mantra via `remoteBuild = true`), pushes over SSH, activates
3. No manual SSH + rebuild needed

## 4. GitHub Actions runners

### Runner configuration

4 runners via `services.github-runners`:

```nix
services.github-runners = builtins.listToAttrs (
  map (n: {
    name = "mantra-${toString n}";
    value = {
      enable = true;
      url = "https://github.com/tonybutt";
      tokenFile = config.sops.secrets.github-runner-token.path;
      extraLabels = [ "nix" ];
      replace = true;
      extraPackages = with pkgs; [ git nix ];
    };
  }) [ 1 2 3 4 ]
);
```

- User-level runners registered to `tonybutt` — available to all personal repos
- Labels: `self-hosted`, `linux`, `x86_64` (defaults) + `nix` (custom)
- `replace = true` for clean re-registration on rebuild
- Each runner gets its own systemd service and working directory under `/var/lib/github-runners/`

### Resource allocation

- 4 runners on 16c/32t + 92GB = ~8 threads / ~23GB per runner at peak
- No cgroup limits — CI builds are bursty, let them share freely
- Persistent Nix store means crane dependency fetches cache across all runners

### No docker

Runners do not get docker access. CI builds use Nix/crane. Docker carries root-equivalent privileges that runners don't need. If container builds are ever needed, add rootless podman as a targeted addition later.

## Files to create/modify

| File                                      | Action                                                                |
| ----------------------------------------- | --------------------------------------------------------------------- |
| `flake.nix`                               | Add sops-nix + deploy-rs inputs, uncomment mantra, add deploy outputs |
| `.sops.yaml`                              | New — age public key mapping for mantra                               |
| `secrets/secrets.yaml`                    | New — encrypted secrets (github-runner-token)                         |
| `hosts/mantra/configuration.nix`          | Rewrite to use shared modules + runner/SSH/VFIO overrides             |
| `hosts/mantra/hardware-configuration.nix` | New placeholder (generated at install)                                |
| `modules/nixos/sops/default.nix`          | New — sops-nix module                                                 |
| `modules/nixos/default.nix`               | Import sops module                                                    |
