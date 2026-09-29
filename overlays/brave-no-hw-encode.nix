# nixpkgs enables AcceleratedVideoEncoder alongside VA-API decode. On the
# Navi 33 that routes WebRTC H.264 through radeonsi's encoder, which produces a
# stream remote Teams attendees can't decode: my local preview looks fine while
# they see no camera, and screen share drops and re-prompts. Meet and Gather
# negotiate VP8/VP9, which radeonsi can't encode, so they were already on the
# software path and never hit this. Hardware decode stays on.
#
# Chromium keeps only the last --disable-features it sees, and commandLineArgs
# lands after the wrapper's own, so the wrapper's list is repeated here. Disable
# wins over the wrapper's --enable-features for the same feature.
#
# Uses .override, so this must come before the overrideAttrs overlays.
_final: prev: {
  brave = prev.brave.override {
    commandLineArgs = "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder,AcceleratedVideoEncoder";
  };
}
