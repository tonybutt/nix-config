# Chromium enables AcceleratedVideoEncoder alongside VA-API decode. On the
# Navi 33 that routes WebRTC H.264 through radeonsi's encoder, which produces a
# stream remote Teams attendees can't decode: my local preview looks fine while
# they see no camera, and screen share drops and re-prompts. Meet and Gather
# negotiate VP8/VP9, which radeonsi can't encode, so they were already on the
# software path and never hit this. Hardware decode stays on.
#
# Chromium keeps only the last --disable-features it sees; the nixpkgs wrapper
# passes none of its own, so this is the whole list.
#
# Uses .override, so this must come before the overrideAttrs overlays.
_final: prev: {
  chromium = prev.chromium.override {
    commandLineArgs = "--disable-features=AcceleratedVideoEncoder";
  };
}
