# Chromium's GetDiskEncrypted() (used by Google Endpoint Verification via
# enterprise device signals) resolves the root filesystem's device by major
# number and probes /sys/dev/block/<major>:0/dm/uuid. Btrfs roots stat as an
# anonymous device (major 0), so LUKS-encrypted btrfs machines report
# "not encrypted". Redirect the probe (same byte length, single occurrence)
# to a path the endpoint-verification service populates with the real
# dm-crypt uuid of the device backing / — an unencrypted root still honestly
# reports unencrypted because the file is simply absent.
#
# nixpkgs' chromium is a wrapper around the separately built chromium.browser;
# patching that derivation would rebuild Chromium from source. Instead copy
# the cached browser directory into the wrapper's output, patch the copy and
# point the wrapper at it. The wrapper is a buildCommand derivation, so the
# phase hooks never run and the work is appended to buildCommand.
#
# Rewrites the exec path in $out/bin/chromium, so this must come before
# chromium-render-node.nix wraps that script again.
final: prev: {
  chromium = prev.chromium.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      unwrapped=${old.passthru.browser}/libexec/chromium
      mkdir -p $out/libexec
      cp -a "$unwrapped" $out/libexec/chromium
      chmod -R u+w $out/libexec/chromium

      bin=$out/libexec/chromium/chromium
      sizeBefore=$(stat -c %s "$bin")
      ${final.perl}/bin/perl -0777 -pi -e \
        's|/sys/dev/block/%d:0/dm/uuid\x00|/run/ev-dm/%d:0/dm/uuid\x00\x00\x00\x00\x00|g' \
        "$bin"
      grep -q '/run/ev-dm/%d:0/dm/uuid' "$bin" || {
        echo "endpoint-verification dm-uuid patch did not apply" >&2
        exit 1
      }
      [ "$sizeBefore" = "$(stat -c %s "$bin")" ] || {
        echo "endpoint-verification dm-uuid patch changed binary size" >&2
        exit 1
      }

      substituteInPlace $out/bin/chromium --replace-fail "$unwrapped/chromium" "$bin"
    '';
  });
}
