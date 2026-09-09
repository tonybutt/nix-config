# deploy-rs.cachix.org is no longer populated, so the flake's own package is
# always a from-source build. Take the binary from nixpkgs (cache.nixos.org)
# and keep only the activation/check helpers from the flake, as documented in
# https://github.com/serokell/deploy-rs#overall-usage
{ deploy-rs }:
final: prev:
let
  upstream = deploy-rs.overlays.default final prev;
in
{
  deploy-rs = {
    inherit (prev) deploy-rs;
    inherit (upstream.deploy-rs) lib;
  };
}
