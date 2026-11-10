# zstd-sys in flake-checker 0.2.15's vendored deps now probes pkg-config for a
# system libzstd, but the nixpkgs package declares neither, so the build panics
# and takes the devshell's pre-commit hook down with it. Drop this once nixpkgs
# adds pkg-config and zstd to pkgs/by-name/fl/flake-checker.
_final: prev: {
  flake-checker = prev.flake-checker.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [ prev.zstd ];
  });
}
