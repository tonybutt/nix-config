# shellcheck disable=SC2148
cp -R /iso/cfg /tmp/cfg
echo "Generating NixOS Hardware Configuration"
nixos-generate-config --dir "/tmp/cfg/hosts/__HOSTNAME__" --no-filesystems
sed -i 's|# \./hardware-configuration\.nix|./hardware-configuration.nix|' "/tmp/cfg/hosts/__HOSTNAME__/configuration.nix"

echo "Partitioning Drive and Installing NixOS"
disko-install --flake "/tmp/cfg#__HOSTNAME__" --disk main __DRIVE__ --write-efi-boot-entries

echo "Mounting Filesystems"
mount -o subvol=root,compress=zstd,noatime /dev/mapper/crypted /mnt
mount -o subvol=home,compress=zstd,noatime /dev/mapper/crypted /mnt/home
mount -o subvol=nix,compress=zstd,noatime /dev/mapper/crypted /mnt/nix
mount /dev/disk/by-label/BOOT /mnt/boot

echo "Copying Configuration to Installed System"
mkdir -p /mnt/home/__USER__/nix-config
cp -R /tmp/cfg/** /mnt/home/__USER__/nix-config

echo "Setting user __USER__ password"
nixos-enter -c 'passwd __USER__'
nixos-enter -c 'chown -R __USER__:users /home/__USER__/nix-config'
nixos-enter -c 'chmod +w -R /home/__USER__/nix-config'
