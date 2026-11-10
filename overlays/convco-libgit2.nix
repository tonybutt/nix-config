# nixpkgs' cargo setup hook now exports LIBGIT2_NO_VENDOR=1, so convco 0.7.2's
# libgit2-sys (built with its sha256 feature) must find a system
# libgit2-experimental. The convco package lists no libgit2 at all, so the
# build panics. Supply one with EXPERIMENTAL_SHA256 on; drop this once nixpkgs
# fixes pkgs/by-name/co/convco.
_final: prev: {
  convco = prev.convco.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      (prev.libgit2.override { withExperimentalSha256 = true; })
    ];
  });
}
