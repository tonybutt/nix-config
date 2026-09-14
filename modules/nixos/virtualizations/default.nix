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
    modules.virtualization = {
      enable = mkEnableOption "Enable virtualization" // {
        default = true;
      };
      vms.enable = mkEnableOption "Enable KVM/QEMU virtual machines";
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      users.users.${user.username}.extraGroups = mkAfter [ "docker" ];

      environment.systemPackages = with pkgs; [
        skopeo
      ];

      virtualisation = {
        docker.enable = true;
        containers.enable = true;

        podman = {
          enable = true;
          dockerSocket.enable = false;
          defaultNetwork.settings.dns_enabled = true;
        };
      };
    }

    (mkIf cfg.vms.enable {
      boot.kernelModules = [ "vfio-pci" ];

      users.users.${user.username}.extraGroups = mkAfter [
        "libvirtd"
        "qemu-libvirtd"
        "kvm"
      ];

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
    })
  ]);
}
