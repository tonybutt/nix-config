# nix-config

Personal NixOS and Home Manager configuration flake.

## Table of Contents

| Section                               | Description                          |
| ------------------------------------- | ------------------------------------ |
| [Goals](#goals)                       | Design principles                    |
| [Exported Modules](#exported-modules) | Reusable modules for external flakes |
| [Installation](#installation)         | ISO creation and system install      |

---

## Goals

- Keep the config simple and only abstract when necessary to support multiple machines
- Keep home configuration completely separate from system configuration, allowing the home configuration to be portable across hosts

---

## Exported Modules

### Claude Cognitive

Home Manager module for [claude-cognitive](https://github.com/GMaN1911/claude-cognitive) - persistent working memory for Claude Code.

> [!NOTE]
> This module provides automatic context routing and multi-instance coordination for Claude Code, reducing token usage by up to 79%.

| Output                         | Path                                 |
| ------------------------------ | ------------------------------------ |
| `homeModules.claude-cognitive` | `modules/hm/ai/claude-cognitive.nix` |

#### Installation

<details>
<summary><strong>1. Add flake input</strong></summary>

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    abutt-nix-config = {
      url = "github:abutt/nix-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

</details>

<details>
<summary><strong>2. Import and enable module</strong></summary>

```nix
homeConfigurations."youruser" = home-manager.lib.homeManagerConfiguration {
  modules = [
    abutt-nix-config.homeModules.claude-cognitive
    {
      modules.ai.claude-cognitive = {
        enable = true;
        instanceId = "A";  # Optional, for multi-instance coordination
      };
    }
  ];
};
```

</details>

> [!TIP]
> Set different `instanceId` values (A, B, C, etc.) for each terminal when running multiple Claude Code instances to enable state sharing between them.

#### What It Provides

| Item                      | Description                                          |
| ------------------------- | ---------------------------------------------------- |
| `~/.claude-cognitive`     | Source repository                                    |
| `~/.claude/scripts`       | Context routing and pool coordination scripts        |
| `~/.claude/settings.json` | Claude Code hooks configuration                      |
| `CLAUDE_INSTANCE`         | Environment variable for multi-instance coordination |
| `python3`                 | Runtime dependency                                   |
| `claude-cognitive-init`   | Command to initialize projects                       |

#### Per-Project Setup

After rebuilding, initialize any project:

```sh
cd /path/to/your/project
claude-cognitive-init
```

> [!IMPORTANT]
> Edit `.claude/CLAUDE.md` with your project info after initialization. This file tells Claude Code about your project's architecture and conventions.

---

## Installation

### Create ISO

```sh
HOSTNAME=<hostname> nix run --show-trace nixpkgs#nixos-generators -- --format iso --flake .#iso -o result
sudo dd if=result/iso/nixinstaller.iso of=/dev/sda bs=4M status=progress conv=fdatasync
```

> [!CAUTION]
> The `dd` command will overwrite the target device. Double-check the device path before running.

### Install NixOS

Boot from the ISO, then run:

```sh
sudo run-install
```
