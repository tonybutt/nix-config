# Stopgap: waybar reads the numeric workspace `id` that Hyprland removed in
# hyprwm/Hyprland#16140. Remove this overlay and the `waybar-src` input once the
# fix lands in nixpkgs. Ref https://github.com/Alexays/Waybar/issues/5316
{ waybar-src }:
_final: prev:
let
  inherit (prev) lib;
in
{
  # cava off: master wants libcava >= 1.0.0, nixpkgs pins 0.10.7-beta.
  waybar =
    (prev.waybar.override {
      runTests = true;
      cavaSupport = false;
    }).overrideAttrs
      (old: {
        src = waybar-src;

        # nixpkgs forces -Dauto_features=enabled; these options are new to master
        # and pull in dependencies it does not provide.
        mesonFlags = (old.mesonFlags or [ ]) ++ [
          (lib.mesonEnable "wwan" false)
          (lib.mesonEnable "logind" false)
          (lib.mesonBool "mango" false)
          (lib.mesonBool "login-proxy" false)
        ];
      });
}
