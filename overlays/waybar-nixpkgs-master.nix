# Stopgap: waybar 0.16.0 carries the Alexays/Waybar#5316 fix for the numeric
# workspace `id` that Hyprland removed in hyprwm/Hyprland#16140, but has only
# reached nixpkgs master. Remove this overlay, the `nixpkgs-master` input, and
# the `waybar-unstable` hook in pre-commit.nix once nixos-unstable has it.
{ nixpkgs-master }:
_final: prev: {
  inherit (nixpkgs-master.legacyPackages.${prev.stdenv.hostPlatform.system}) waybar;
}
