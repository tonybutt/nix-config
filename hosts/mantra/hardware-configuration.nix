# Placeholder — replace with output of nixos-generate-config after install.
# The actual hardware scan will populate kernel modules, filesystems, etc.
{
  imports = [ ];

  # Will be populated by nixos-generate-config:
  # - boot.initrd.availableKernelModules
  # - boot.kernelModules
  # - hardware.cpu.amd.updateMicrocode
  # - fileSystems
  # - swapDevices

  # Required for the build to succeed before install
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.grub.device = "nodev";
}
