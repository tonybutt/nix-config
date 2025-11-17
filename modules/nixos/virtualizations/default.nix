{
  pkgs,
  config,
  lib,
  user,
  ...
}:
with lib;
let
  cfg = config.modules.virtualization;
in
{
  options = {
    modules.virtualization.enable = mkEnableOption "Enable virtualization" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    boot.kernelModules = [ "vfio-pci" ];

    users = {
      users.${user.name} = {
        extraGroups = mkAfter [
          "docker"
          "libvirtd"
          "qemu-libvirtd"
          "kvm"
        ];
      };
    };

    networking.firewall.trustedInterfaces = [
      "virbr0"
      "br0"
    ];

    services.udev.extraRules = ''
      # Supporting VFIO
      SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"
    '';

    environment.systemPackages = with pkgs; [
      virt-manager
      qemu_kvm
      qemu
    ];

    virtualisation = {
      docker.enable = true;
      containers.enable = true;
      kvmgt.enable = true;
      spiceUSBRedirection.enable = true;

      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;

          verbatimConfig = ''
            namespaces = []

            # Whether libvirt should dynamically change file ownership
            dynamic_ownership = 0
          '';
        };

        onBoot = "ignore";
        onShutdown = "shutdown";
      };
    };

  };
}
