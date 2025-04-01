# NixOS Configuration Guide

## Build Commands
- Format code: `nix fmt`
- Build ISO: `HOSTNAME=<hostname> DRIVE_PASSWORD=<pass> GITLAB_TOKEN=<token> nix run nixpkgs#nixos-generators -- --format iso --flake .#iso -o result`
- Install system: `sudo run-install`
- Switch to new configuration: `sudo nixos-rebuild switch --flake .#<hostname>`
- Update home configuration: `home-manager switch --flake .#anthony`

## Code Style Guidelines
- Use RFC-style Nix formatting (enforced by nixfmt-rfc-style)
- Keep configurations simple, abstract only when necessary
- Maintain clear separation between home and system configurations
- Follow the existing directory structure:
  - `/hosts/<hostname>/` for system configurations
  - `/home/` for home-manager configuration

## Project Values
- Simplicity over complexity
- Clear separation of concerns
- Host-specific configurations with minimal abstraction