# Google Endpoint Verification native helper. The Brave extension talks to
# apihelper over native messaging (manifest installed by home-manager);
# serial number and disk encryption are read by the browser's own enterprise
# device-signals code, with the encryption probe redirected to /run/ev-dm by
# the brave overlay (see overlays/brave-endpoint-verification.nix).
{ pkgs, ... }:
let
  endpoint-verification = pkgs.callPackage ./package.nix { };
  helperRoot = "${endpoint-verification}/opt/google/endpoint-verification";

  evInit = pkgs.writeShellScript "endpoint-verification-init" ''
    set -eu
    PATH=${
      pkgs.lib.makeBinPath [
        pkgs.coreutils
        pkgs.util-linux
        pkgs.gnused
      ]
    }

    ${helperRoot}/bin/device_state.sh init > /var/lib/endpoint-verification/device_attrs

    # Mirror the dm-crypt uuid of the device backing / to the path Brave is
    # patched to probe: /run/ev-dm/<major of stat("/")>:0/dm/uuid. Btrfs
    # roots stat as anonymous major 0, which Chromium's stock /sys probe
    # cannot resolve. If the backing device is not dm-crypt, no file is
    # written and Brave keeps reporting unencrypted.
    chrome_major=$(stat -c %Hd /)
    src=$(findmnt -no SOURCE / | sed 's|\[.*||')
    if [ -b "$src" ]; then
      uuid_file="/sys/dev/block/$(stat -Lc %Hr:%Lr "$src")/dm/uuid"
      if [ -r "$uuid_file" ]; then
        case "$(cat "$uuid_file")" in
          [Cc][Rr][Yy][Pp][Tt]-*)
            mkdir -p "/run/ev-dm/$chrome_major:0/dm"
            cat "$uuid_file" > "/run/ev-dm/$chrome_major:0/dm/uuid"
            ;;
        esac
      fi
    fi
  '';
in
{
  # apihelper hardcodes /opt/google/endpoint-verification internally
  systemd.tmpfiles.rules = [
    "d /opt 0755 root root -"
    "d /opt/google 0755 root root -"
    "L+ /opt/google/endpoint-verification - - - - ${helperRoot}"
  ];

  # Root oneshot capturing attrs a regular user can't read directly.
  systemd.services.endpoint-verification = {
    description = "Endpoint Verification device attribute generation";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = evInit;
      StateDirectory = "endpoint-verification";
    };
  };
}
