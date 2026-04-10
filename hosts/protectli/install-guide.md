# Protectli FW4C — OPNsense Install Guide

## Prerequisites

- Protectli FW4C (4-port, Intel J3710)
- 2x USB drives (one for installer, one for config)
- Keyboard + monitor (or serial console) for initial install
- Yubikey with SK keys enrolled

## 1. Download OPNsense

Download the latest OPNsense AMD64 image from:
https://opnsense.org/download/

Select: **amd64**, **dvd** (USB installer), **bz2**

## 2. Flash Installer to USB

```bash
bunzip2 OPNsense-*.bz2
sudo dd if=OPNsense-*.img of=/dev/sdX bs=4M status=progress
sync
```

## 3. Generate Bootstrap Config

```bash
cd ~/nix-config

# Generate API credentials first
API_KEY=$(openssl rand -hex 40)
API_SECRET=$(openssl rand -hex 40)
echo "API Key: $API_KEY"
echo "API Secret: $API_SECRET"
# Save these — you'll need them for opnsctl.toml secret files

# Build the config (update apiKey/apiSecretHash in flake.nix first)
nix build .#opnsense-config
```

## 4. Prepare Config USB

Format a second USB drive as FAT32 and copy the config:

```bash
sudo mkfs.vfat /dev/sdY1
sudo mount /dev/sdY1 /mnt
sudo mkdir -p /mnt/conf
sudo cp result /mnt/conf/config.xml
sudo umount /mnt
```

## 5. Install OPNsense

1. Connect keyboard + monitor to FW4C
2. Insert installer USB
3. Boot FW4C — enter BIOS if needed to set USB boot priority
4. Follow OPNsense installer — accept defaults, install to internal SSD
5. Remove installer USB, reboot

## 6. Import Config

1. On reboot, insert the config USB
2. OPNsense importer detects `/conf/config.xml` and offers to load it
3. Accept the import
4. Remove config USB, reboot

## 7. Verify Access

### SSH

```bash
ssh root@192.168.1.1
# Should prompt for Yubikey touch
```

### Web GUI

Browse to `https://192.168.1.1` — login with root credentials.

## 8. Cable Up

```
Cable modem → igb0 (WAN)
Ubiquiti switch → igb1 (LAN)
Starlink (bypass mode) → igb2 (OPT1/STARLINK)
```

Enable bypass mode in the Starlink app first.

## 9. Apply Day-2 Config

```bash
# Set up secret files with the API credentials from step 3
mkdir -p /run/secrets
echo -n "$API_KEY" > /run/secrets/opnsctl-api-key
echo -n "$API_SECRET" > /run/secrets/opnsctl-api-secret

# Preview changes
opnsctl apply --config hosts/protectli/opnsctl.toml --dry-run

# Apply
opnsctl apply --config hosts/protectli/opnsctl.toml
```

## 10. Verify

```bash
# Check gateway status
opnsctl status --config hosts/protectli/opnsctl.toml

# Both WANs should show as online
```

## Starlink Notes

- CGNAT (100.64.x.x) means no inbound port forwarding through Starlink
- Bypass mode: enable in Starlink app under Settings
- "Block private networks" is already unchecked on OPT1 in the bootstrap config
- Gateway monitoring uses separate IPs (8.8.8.8 for cable, 1.1.1.1 for Starlink)
- Starlink trigger set to `packet_loss_or_latency` to avoid false failovers
