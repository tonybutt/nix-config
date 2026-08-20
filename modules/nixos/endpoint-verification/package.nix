{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  coreutils,
  gawk,
  gnugrep,
  util-linux,
  systemd,
  hostname,
  glib,
  dconf,
}:

stdenv.mkDerivation rec {
  pname = "endpoint-verification";
  version = "1765828494702-842239260";

  src = fetchurl {
    url = "https://packages.cloud.google.com/apt/pool/endpoint-verification/endpoint-verification_${version}_amd64_3bcef7ad4e9e6bf8b16dae869190fca7.deb";
    hash = "sha256-LqglFD/VahDWrjo/JxnNR4M0effdP6pu7X9izi0KxmQ=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r opt $out/

    # apihelper (spawned by the browser as the logged-in user) invokes this
    # script at a hardcoded /opt path; the NixOS module symlinks /opt/google/
    # endpoint-verification back to this package.
    substituteInPlace $out/opt/google/endpoint-verification/bin/device_state.sh \
      --replace-fail 'AWK=/usr/bin/awk' 'AWK=${gawk}/bin/awk' \
      --replace-fail 'CAT=/bin/cat' 'CAT=${coreutils}/bin/cat' \
      --replace-fail 'CUT=/usr/bin/cut' 'CUT=${coreutils}/bin/cut' \
      --replace-fail 'DCONF=/usr/bin/dconf' 'DCONF=${dconf}/bin/dconf' \
      --replace-fail 'ECHO=/bin/echo' 'ECHO=${coreutils}/bin/echo' \
      --replace-fail 'GREP=/bin/grep' 'GREP=${gnugrep}/bin/grep' \
      --replace-fail 'GSETTINGS=/usr/bin/gsettings' 'GSETTINGS=${lib.getBin glib}/bin/gsettings' \
      --replace-fail 'LSBLK=/bin/lsblk' 'LSBLK=${util-linux}/bin/lsblk' \
      --replace-fail 'MOUNTPOINT=/bin/mountpoint' 'MOUNTPOINT=${util-linux}/bin/mountpoint' \
      --replace-fail 'PRINTF=/usr/bin/printf' 'PRINTF=${coreutils}/bin/printf' \
      --replace-fail 'STAT=/usr/bin/stat' 'STAT=${coreutils}/bin/stat' \
      --replace-fail 'TR=/usr/bin/tr' 'TR=${coreutils}/bin/tr' \
      --replace-fail 'UDEVADM=/bin/udevadm' 'UDEVADM=${systemd}/bin/udevadm' \
      --replace-fail '/bin/hostname' '${hostname}/bin/hostname' \
      --replace-fail 'GENERATED_ATTRS_FILE="$INSTALL_PREFIX/var/lib/device_attrs"' \
        'GENERATED_ATTRS_FILE=/var/lib/endpoint-verification/device_attrs' \
      --replace-fail '*ubuntu*|*debian*)' '*)' \
      --replace-fail 'ROOT_MAJ=$("$PRINTF" "%d" 0x"$ROOT_MAJ_HEX")' \
        'ROOT_MAJ=$("$PRINTF" "%d" 0x"$ROOT_MAJ_HEX" 2>/dev/null)' \
      --replace-fail 'if [ "$ROOT_MAJ" = "" ]; then' \
        'if [ "$ROOT_MAJ" = "" ] || [ "$ROOT_MAJ" = "0" ]; then' \
      --replace-fail 'ACTION=''${1:-default}' 'ACTION=''${1:-default}

    # Defaults so `set -u` cannot abort mid-report when a probe finds
    # nothing (e.g. no ufw on NixOS); btrfs roots report anonymous device
    # major 0, handled by the ROOT_MAJ fallback patch above.
    SERIAL_NUMBER=""
    DISK_ENCRYPTED=UNKNOWN
    OS_VERSION=""
    OS_FIREWALL=""
    MAC_ADDRESSES=""
    SCREENLOCK_ENABLED=UNKNOWN
    HOSTNAME=""
    MODEL=""'

    patchShebangs $out/opt/google/endpoint-verification/bin/device_state.sh

    runHook postInstall
  '';

  meta = {
    description = "Google Endpoint Verification native helper";
    homepage = "https://cloud.google.com/endpoint-verification/docs/overview";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
