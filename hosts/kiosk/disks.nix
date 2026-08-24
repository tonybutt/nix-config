# NVMe layout for the M.2 HAT SSD (phase 2 — replaces the sd-image module
# in the flake entry at install time). The firmware "kernel" bootloader
# keeps every generation's kernel+initrd (~65M each) in FIRMWARE, so give
# it headroom.
{
  disko.devices = {
    disk.nvme = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          FIRMWARE = {
            priority = 1;
            label = "FIRMWARE";
            type = "0700"; # Microsoft basic data — what the Pi firmware scans for
            attributes = [ 0 ]; # Required Partition
            size = "2048M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
              ];
            };
          };
          root = {
            label = "NIXOS_ROOT";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
  };
}
