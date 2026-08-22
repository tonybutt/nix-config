# kiosk — Raspberry Pi 5 kiosk

Raspberry Pi 5 (M.2 HAT) running a fullscreen chromium kiosk under
[cage](https://github.com/cage-kiosk/cage). Built with
[nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) rather than
nixos-hardware: it boots the kernel directly via the Pi firmware (no U-Boot),
which is what makes SD-free NVMe boot possible later, and uses the
generation-aware `kernel` bootloader so NixOS rollbacks work.

Unlike the other hosts this is a special case in `flake.nix` — aarch64, no
Stylix/themes/disko, not part of `mkSystem`. It imports only
`modules/nixos/ssh` and `modules/nixos/users`.

The displayed URL is the `kioskUrl` binding at the top of
`configuration.nix`.

## Build & flash the SD image

```sh
nix build .#kiosk-sd          # needs binfmt aarch64 on the builder (atlas has it)
zstdcat result/sd-image/nixos-image-rpi5-kernel.img.zst \
  | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

First boot auto-expands the root partition. The host announces itself as
`kiosk.local` via mDNS (avahi); SSH is key-only and firewalled to the LAN
subnet (`modules.ssh.lanSubnet`).

## Update a running kiosk

```sh
deploy .#kiosk
```

## Old-EEPROM gotcha (7 green blinks)

Pi 5s with 2023-era shipped EEPROM fail to boot the `kernel` bootloader with
**7 blinks = "kernel not found"** even though the card is fine
([nixos-raspberrypi#121](https://github.com/nvmd/nixos-raspberrypi/issues/121)).
Fix without a monitor or second OS: put the EEPROM recovery trio on the
FIRMWARE partition and boot once —

```sh
# files from https://github.com/raspberrypi/rpi-eeprom firmware-2712/default/
cp recovery.bin /run/media/$USER/FIRMWARE/
cp pieeprom-<date>.bin /run/media/$USER/FIRMWARE/pieeprom.upd
sha256sum pieeprom.upd | cut -c1-64 > /run/media/$USER/FIRMWARE/pieeprom.sig
```

Success: `recovery.bin` renames itself to `RECOVERY.000`. Delete the leftover
`pieeprom.*` files and boot normally.

## Phase 2 — move to NVMe (planned)

1. Confirm the SSD enumerates from the running SD system (`lsblk`); if not,
   add `PCIE_PROBE=1` to the EEPROM config.
2. Add a disko NVMe layout (see nixos-raspberrypi-demo `disko-nvme-*.nix`) and
   swap the `sd-image` module out of the flake entry.
3. Provision with `nixos-anywhere --flake .#kiosk root@kiosk.local`
   (deploy-rs only updates existing systems; it can't partition disks).
4. `rpi-eeprom-config --edit` → `BOOT_ORDER=0xf416` (NVMe → SD → USB), then
   pull the SD card and keep it as a rescue boot.
