# Mantra Runner Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn mantra into a self-hosted GitHub Actions runner host with sops-nix secrets, hardened SSH, and deploy-rs for remote management.

**Architecture:** Add sops-nix and deploy-rs as flake inputs. Refactor mantra's configuration to use the shared `modules/nixos` system. Create a new sops module for secret management, configure 4 GitHub Actions runners backed by an encrypted PAT, harden SSH for yubikey-sk access, and expose a deploy-rs node for remote rebuilds from atlas/lapnix.

**Tech Stack:** NixOS, sops-nix, deploy-rs, services.github-runners, openssh

---

## File Structure

| File                                      | Action  | Responsibility                                                              |
| ----------------------------------------- | ------- | --------------------------------------------------------------------------- |
| `flake.nix`                               | Modify  | Add sops-nix + deploy-rs inputs, uncomment mantra, add deploy outputs       |
| `hosts/mantra/configuration.nix`          | Rewrite | Use shared modules, add mantra-specific overrides (SSH, runners, VM, steam) |
| `hosts/mantra/hardware-configuration.nix` | Create  | Placeholder — generated at install time, imports disko                      |
| `modules/nixos/sops/default.nix`          | Create  | sops-nix NixOS module with default config                                   |
| `modules/nixos/default.nix`               | Modify  | Import sops module                                                          |
| `.sops.yaml`                              | Create  | Placeholder sops config with instructions for adding host keys              |
| `secrets/.gitkeep`                        | Create  | Placeholder for secrets directory (secrets.yaml added post-install)         |

---

### Task 1: Add sops-nix and deploy-rs flake inputs

**Files:**

- Modify: `flake.nix:1-29` (inputs block)

- [ ] **Step 1: Add sops-nix input**

In `flake.nix`, add after the `pre-commit-hooks` input (line 23):

```nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Add deploy-rs input**

In `flake.nix`, add after the new `sops-nix` input:

```nix
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 3: Add to outputs function args**

In `flake.nix`, add `sops-nix` and `deploy-rs` to the destructured outputs args (around line 51 area, alongside `pre-commit-hooks`):

```nix
      sops-nix,
      deploy-rs,
```

- [ ] **Step 4: Run `nix flake lock --update-input sops-nix --update-input deploy-rs`**

Expected: lock file updates with new inputs, no errors.

- [ ] **Step 5: Run `nix flake check`**

Expected: passes (no config references the new inputs yet).

- [ ] **Step 6: Commit**

```bash
git add flake.nix flake.lock
git commit -m "build: add sops-nix and deploy-rs flake inputs"
```

---

### Task 2: Create sops-nix NixOS module

**Files:**

- Create: `modules/nixos/sops/default.nix`
- Modify: `modules/nixos/default.nix:13-20` (imports list)

- [ ] **Step 1: Create the sops module**

Create `modules/nixos/sops/default.nix`:

```nix
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.sops;
in
{
  options = {
    modules.sops.enable = mkEnableOption "Enable sops-nix secret management";
  };
  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      secrets = {
        github-runner-token = { };
      };
    };
  };
}
```

- [ ] **Step 2: Import sops module in modules/nixos/default.nix**

Add `./sops` to the imports list in `modules/nixos/default.nix` (line 13-20):

```nix
  imports = [
    ./packages.nix
    ./wms
    ./peripherals
    ./users
    ./virtualizations
    ./laptop.nix
    ./sops
  ];
```

- [ ] **Step 3: Wire sops-nix NixOS module into the flake's mkSystem**

In `flake.nix`, inside the `mkSystem` function's `modules` list (around line 139-151), add the sops-nix NixOS module import so it's available to all hosts:

```nix
modules = hardwareModules ++ [
  { nixpkgs.hostPlatform = system; }
  ./hosts/${hostname}/configuration.nix
  stylix.nixosModules.stylix
  disko.nixosModules.disko
  sops-nix.nixosModules.sops
  ./modules/stylix
  {
    modules.themes.theme = themeConfig.scheme;
    modules.themes.wallpaper = themeConfig.wallpaper;
    modules.themes.polarity = themeConfig.polarity;
  }
];
```

- [ ] **Step 4: Create secrets directory placeholder**

```bash
mkdir -p secrets
touch secrets/.gitkeep
```

- [ ] **Step 5: Create .sops.yaml placeholder**

Create `.sops.yaml` at repo root:

```yaml
# Add host age public keys here after install.
# Convert SSH host key to age key:
#   nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
#
# Then run: sops secrets/secrets.yaml
keys: []
creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age: []
```

- [ ] **Step 6: Commit**

```bash
git add modules/nixos/sops/default.nix modules/nixos/default.nix .sops.yaml secrets/.gitkeep flake.nix
git commit -m "feat(sops): add sops-nix module and secrets scaffolding"
```

---

### Task 3: Uncomment mantra in flake and create placeholder hardware config

**Files:**

- Modify: `flake.nix:107-127` (hosts map) and `flake.nix:171-176` (homeConfigurations hostDefaults)
- Create: `hosts/mantra/hardware-configuration.nix`

- [ ] **Step 1: Uncomment mantra in nixosConfigurations hosts**

In `flake.nix`, uncomment the mantra entry in the `hosts` attrset (lines 119-122) and set the hardware modules:

```nix
            mantra = {
              hardwareModules = [
                nixos-hardware.nixosModules.common-cpu-amd
                nixos-hardware.nixosModules.common-cpu-amd-pstate
                nixos-hardware.nixosModules.common-gpu-amd
                nixos-hardware.nixosModules.common-pc
                nixos-hardware.nixosModules.common-pc-ssd
              ];
              theme = "final-fantasy";
            };
```

- [ ] **Step 2: Uncomment mantra in homeConfigurations hostDefaults**

In `flake.nix`, uncomment the mantra entry in `hostDefaults` (line 175):

```nix
            mantra = "final-fantasy";
```

- [ ] **Step 3: Create placeholder hardware-configuration.nix**

Create `hosts/mantra/hardware-configuration.nix`:

```nix
# Placeholder — replace with output of nixos-generate-config after install.
# The actual hardware scan will populate kernel modules, filesystems, etc.
{
  imports = [ ];

  # Will be populated by nixos-generate-config:
  # - boot.initrd.availableKernelModules
  # - boot.kernelModules
  # - hardware.cpu.amd.updateMicrocode
  # - fileSystems
  # - swapDevices

  # Required for the build to succeed before install
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.grub.device = "nodev";
}
```

- [ ] **Step 4: Verify the flake evaluates**

Run: `nix flake check --no-build 2>&1 | head -30`

Expected: no evaluation errors for the mantra configuration. There may be warnings about the placeholder hardware config, which is fine.

- [ ] **Step 5: Commit**

```bash
git add flake.nix hosts/mantra/hardware-configuration.nix
git commit -m "feat(mantra): uncomment mantra in flake with nixos-hardware modules"
```

---

### Task 4: Rewrite mantra configuration.nix

**Files:**

- Rewrite: `hosts/mantra/configuration.nix`

This replaces the entire 303-line legacy config with a clean version that uses the shared modules, following the tiberius pattern.

- [ ] **Step 1: Rewrite hosts/mantra/configuration.nix**

Replace the entire file with:

```nix
{
  pkgs,
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
  networking.wireless.enable = false;

  # GPU — RX 6900 XT (RDNA 2)
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    amdgpu.amdvlk = {
      enable = true;
      support32Bit.enable = true;
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    font-awesome
    cascadia-code
    (nerdfonts.override {
      fonts = [
        "NerdFontsSymbolsOnly"
        "FiraCode"
      ];
    })
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

  # GitHub Actions runners (4x user-level for tonybutt)
  services.github-runners = builtins.listToAttrs (
    map (n: {
      name = "mantra-${toString n}";
      value = {
        enable = true;
        url = "https://github.com/tonybutt";
        tokenFile = config.sops.secrets.github-runner-token.path;
        extraLabels = [ "nix" ];
        replace = true;
        extraPackages = with pkgs; [
          git
          nix
        ];
      };
    }) [ 1 2 3 4 ]
  );

  system.stateVersion = "24.05";
}
```

- [ ] **Step 2: Verify evaluation**

Run: `nix eval .#nixosConfigurations.mantra.config.system.build.toplevel --no-build 2>&1 | head -20`

Expected: evaluates without errors (may not build without real hardware config, but should evaluate).

- [ ] **Step 3: Commit**

```bash
git add hosts/mantra/configuration.nix
git commit -m "refactor(mantra): rewrite config to use shared modules

Replaces 300-line standalone config with clean shared-module
pattern. Adds SSH server, GitHub Actions runners, sops
integration, and mantra-specific overrides for GPU/steam/VMs."
```

---

### Task 5: Add deploy-rs outputs to flake

**Files:**

- Modify: `flake.nix` (outputs section, after `homeConfigurations`)

- [ ] **Step 1: Add deploy-rs outputs**

In `flake.nix`, add a `deploy` output after the `homeConfigurations` block closes (before the final closing braces, around line 228):

```nix
      deploy.nodes.mantra = {
        hostname = "mantra";
        profiles.system = {
          user = "root";
          sshUser = user.username;
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mantra;
        };
      };

      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;
```

Wait — that would overwrite the existing `checks` output. Instead, merge it:

```nix
      deploy.nodes.mantra = {
        hostname = "mantra";
        profiles.system = {
          user = "root";
          sshUser = user.username;
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mantra;
        };
      };
```

And merge deploy-rs checks into the existing `checks.${system}` attrset (around line 88):

```nix
      checks.${system} = {
        pre-commit-check = pkgs.callPackage ./pre-commit.nix {
          inherit pre-commit-hooks treefmtEval;
        };
      } // (deploy-rs.lib.${system}.deployChecks self.deploy);
```

- [ ] **Step 2: Add deploy-rs to devShell packages**

In `flake.nix`, add `deploy-rs.packages.${system}.default` to the devShell packages so `deploy` is available from the dev shell (around line 94):

```nix
      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        packages = [
          (self.checks.${system}.pre-commit-check.enabledPackages)
          treefmtEval.config.build.wrapper
          deploy-rs.packages.${system}.default
        ];
        env = {
          CLAUDE_INSTANCE = "nix-config";
          CONTEXT_DOCS_ROOT = "/home/anthony/nix-config/.claude";
        };
      };
```

- [ ] **Step 3: Verify evaluation**

Run: `nix flake check --no-build 2>&1 | head -30`

Expected: no evaluation errors.

- [ ] **Step 4: Commit**

```bash
git add flake.nix
git commit -m "feat(deploy): add deploy-rs node for mantra

Enables remote rebuilds via 'deploy .#mantra' from atlas/lapnix
over SSH. Includes deploy checks merged into flake checks."
```

---

### Task 6: Validate full flake evaluation

This is a final integration check before the ISO can be built.

**Files:** None — validation only.

- [ ] **Step 1: Check all NixOS configurations evaluate**

Run: `nix flake check --no-build 2>&1`

Expected: all configurations evaluate without errors. Build is not attempted (no real hardware config on mantra yet).

- [ ] **Step 2: Verify ISO still builds**

Run: `nix build .#nixosConfigurations.iso.config.system.build.isoImage --dry-run 2>&1 | head -20`

Expected: dry-run succeeds, showing the derivation that would be built.

- [ ] **Step 3: Verify mantra NixOS config evaluates**

Run: `nix eval .#nixosConfigurations.mantra.config.networking.hostName`

Expected: `"mantra"`

- [ ] **Step 4: Verify deploy node evaluates**

Run: `nix eval .#deploy.nodes.mantra.hostname`

Expected: `"mantra"`

- [ ] **Step 5: Commit any fixups needed, then tag**

If any fixes were needed in previous steps, commit them. No tag needed — this is just validation.

---

## Post-Install Steps (manual, not automated)

These happen after building the ISO and installing mantra:

1. **Boot mantra from ISO, run install**
2. **SSH in from atlas/lapnix** — grab mantra's host pubkey:
   ```bash
   ssh anthony@mantra cat /etc/ssh/ssh_host_ed25519_key.pub
   ```
3. **Convert to age key:**
   ```bash
   nix-shell -p ssh-to-age --run 'echo "ssh-ed25519 AAAA..." | ssh-to-age'
   ```
4. **Update `.sops.yaml`** with the age public key
5. **Create and encrypt secrets:**
   ```bash
   sops secrets/secrets.yaml
   # Add: github-runner-token: ghp_your_pat_here
   ```
6. **Deploy:**
   ```bash
   deploy .#mantra
   ```
7. **Replace placeholder hardware-configuration.nix** with the one generated during install (`/etc/nixos/hardware-configuration.nix` on mantra)
8. **Replace placeholder SSH pubkey** in `hosts/mantra/configuration.nix` with your actual yubikey-sk public key
9. **Commit and deploy again**
