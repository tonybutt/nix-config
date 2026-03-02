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

## Adding a New Theme

### Using a community base16 scheme

1. Find the scheme name from [base16-schemes](https://github.com/tinted-theming/schemes/tree/spec-0.11/base16) (e.g., `dracula`)
2. Add a wallpaper image to `modules/stylix/assets/walls/`
3. Add an entry to `themes.nix`:

```nix
dracula = {
  scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
  wallpaper = ./modules/stylix/assets/walls/dracula.png;
};
```

### Using a custom scheme

1. Create a base16 YAML file in `modules/stylix/assets/themes/` with all 16 colors (`base00`–`base0F`):

```yaml
scheme: "My Theme"
author: "Your Name"
base00: "1a1b26" # background (darkest)
base01: "1f2233" # lighter background (status bars)
base02: "292e42" # selection background
base03: "444b6a" # comments, inactive borders
base04: "787c99" # subdued UI text
base05: "a9b1d6" # default foreground
base06: "cbccd1" # light foreground
base07: "d5d6db" # lightest foreground
base08: "f7768e" # red — errors, danger
base09: "ff9e64" # orange — warnings, constants
base0A: "e0af68" # yellow — caution, search highlights
base0B: "9ece6a" # green — success, strings
base0C: "7dcfff" # cyan — info, links
base0D: "7aa2f7" # blue — primary accent, functions
base0E: "bb9af7" # purple — secondary accent, keywords
base0F: "c0caf5" # tertiary accent
```

2. Add a wallpaper image to `modules/stylix/assets/walls/`
3. Add an entry to `themes.nix`:

```nix
my-theme = {
  scheme = ./modules/stylix/assets/themes/my_theme.yaml;
  wallpaper = ./modules/stylix/assets/walls/my-theme.png;
};
```

### After adding

Rebuild home (`rbh`) and the new theme will be available via `theme-switch <name>` and in the application launcher.

## Fresh Install

### Modify the with your machine's name [flake](./flake.nix)

Update your user information

```nix
  user = {
    name = "anthony";
    fullName = "Anthony Butt";
    email = "abutt@tiberius.com";
    signingkey = "~/.ssh/id_ed25519_sk.pub";
  };
```

Update the nixosConfigurations block with just your machine and iso

```nix
nixosConfigurations = {
<YOUR_CHOSEN_HOSTNAME> = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inherit user inputs hyprland;
          };
          modules = [
            nixos-hardware.nixosModules.dell-precision-3490-intel
            nixos-hardware.nixosModules.common-gpu-intel
            ./hosts/tiberius/configuration.nix
            stylix.nixosModules.stylix
            disko.nixosModules.disko
          ];
        };
        # Minimal Installation ISO.
        iso = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inherit user;
          };

          modules = [
            ./hosts/iso/configuration.nix
          ];
        };
      };
```

### Create ISO

```sh
HOSTNAME=YOUR_CHOSEN_HOSTNAME nix run nixpkgs#nixos-generators -- --format iso --flake .#iso -o result
# X is not your usbs location. Use lsblk to find the usb you want to write to.
# The iso gets sent to the result folder
sudo dd if=path_to_generated_iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

### Install

Boot from ISO, then:

connect to wifi if not on ethernet:

```sh
sudo nmcli device wifi connect "YourSSID" password "YourPassword"
```

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
