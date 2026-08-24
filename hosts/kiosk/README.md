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

## NVMe (done — this is how the host runs now)

The system lives on the M.2 HAT SSD (`hosts/kiosk/disks.nix`: 2G vfat
FIRMWARE + ext4 root, disko). The May-2026 EEPROM's default
`BOOT_ORDER=0xf461` already falls back to NVMe, so no EEPROM changes were
needed: an inserted SD card always wins the boot order, which makes the old
sd-image card a permanent rescue stick — keep it.

Notes from the install (2026-08-23), should it ever be redone:

- `nixos-anywhere --flake .#kiosk --phases disko,install root@kiosk.local`
  from a builder with aarch64 binfmt; no kexec needed since the NVMe isn't
  the boot disk when installing from the running SD system.
- Temporary root SSH is required (nixos-anywhere needs real root; the sudo
  whitelist is deliberately narrow). Revert it afterwards.
- Root's shell must be bash during the install: nixos-anywhere sends an
  unquoted `local?root=/mnt` store URI through the remote shell and zsh
  aborts on the unmatched glob. Watch out for a cached ssh ControlMaster
  keeping the old shell alive after `usermod`.
- Dropping the `sd-image` module silently reverts
  `boot.loader.raspberry-pi.bootloader` from "kernel" to legacy
  "kernelboot"; it is now pinned explicitly in `configuration.nix`.
- The fresh install generates new SSH host keys: expect a known_hosts
  mismatch on first connect.
