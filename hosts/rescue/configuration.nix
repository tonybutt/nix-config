{
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce removePrefix;
  disk-report = pkgs.writeShellApplication {
    name = "disk-report";
    runtimeInputs = with pkgs; [
      nvme-cli
      smartmontools
      util-linux
      pciutils
      dmidecode
      lshw
    ];
    # The script carries its own shebang so it stays runnable standalone;
    # writeShellApplication supplies one (plus `set -euo pipefail`), so drop
    # it here rather than leaving a stray comment in the derivation.
    text = removePrefix "#!/usr/bin/env bash\n" (builtins.readFile ./disk-report.sh);
  };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  image = {
    baseName = mkForce "nixrescue";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  environment.systemPackages = with pkgs; [
    disk-report

    nvme-cli
    smartmontools
    hdparm
    ddrescue
    e2fsprogs
    gptfdisk
    parted
    util-linux

    pciutils
    usbutils
    dmidecode
    lshw
    ethtool

    tmux
    vim
    git
    curl
    rsync
  ];
}
