# Goals
1. Keep the config simple and only abstract when necessary to support multiple machines.
1. Keep home configuration completely seperate from system configuration. This should allow the home configuration to be put on each host.

## Make ISO
```sh
HOSTNAME=<hostname> DRIVE_PASSWORD=<pass> GITLAB_TOKEN=<token> nix run --show-trace nixpkgs#nixos-generators -- --format iso --flake .#iso -o result
sudo dd if=result/iso/nixinstaller.iso of=/dev/sdc bs=4M status=progress conv=fdatasync
```
## Boot ISO
## Install nixos and flake
```sh
sudo run-install
```
