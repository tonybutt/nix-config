# nix-config

Personal NixOS and Home Manager configuration flake.

## Usage

### Rebuild System

```sh
nh os switch . -H <hostname>
```

Hostnames: `tiberius`, `atlas`, `lapnix`, `mantra`

### Rebuild Home

```sh
nh home switch . -c <username>
```

Use `<username>@<hostname>` for host-specific home configs (e.g., `anthony@lapnix`).

### Update Inputs

```sh
nix flake update
```

Then rebuild system and home to apply updates.

### Format & Check

```sh
nix fmt              # Format all files
nix flake check      # Validate flake and run pre-commit hooks
```

## Structure

```
flake.nix                 # Entry point: inputs, outputs, host definitions
├── hosts/<hostname>/     # Per-machine NixOS config
│   ├── configuration.nix # System config
│   ├── disks.nix         # Disko disk layout
│   └── home-overrides.nix # Optional host-specific home overrides
├── home/home.nix         # Home Manager entry (imports modules/hm)
└── modules/
    ├── hm/               # Home Manager modules (user programs, shell, wm)
    ├── nixos/            # NixOS modules (system packages, services)
    └── stylix/           # Theming
```

## Adding a New Host

1. Create `hosts/<hostname>/configuration.nix` importing `../../modules/nixos`
2. Create `hosts/<hostname>/disks.nix` with disko disk layout
3. Add nixosConfiguration in `flake.nix`:

```nix
<hostname> = nixpkgs.lib.nixosSystem {
  inherit pkgs system;
  specialArgs = { inherit user inputs hyprland; };
  modules = [
    ./hosts/<hostname>/configuration.nix
    stylix.nixosModules.stylix
    disko.nixosModules.disko
  ];
};
```

4. Optionally add host-specific homeConfiguration with overrides

## Fresh Install

### Create ISO

```sh
nix run nixpkgs#nixos-generators -- --format iso --flake .#iso -o result
sudo dd if=result/iso/nixinstaller.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

### Install

Boot from ISO, then:

```sh
sudo run-install
```

---

## Exported Modules

### Claude Cognitive

Home Manager module for [claude-cognitive](https://github.com/GMaN1911/claude-cognitive) - persistent working memory for Claude Code.

**Add to your flake:**

```nix
inputs.abutt-nix-config.url = "github:abutt/nix-config";
```

**Enable in home configuration:**

```nix
modules = [
  abutt-nix-config.homeModules.claude-cognitive
  { modules.ai.claude-cognitive.enable = true; }
];
```

**Initialize per-project:**

```sh
cd /path/to/project && claude-cognitive-init
```
