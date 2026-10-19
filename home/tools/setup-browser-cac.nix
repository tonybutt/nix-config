{ pkgs, ... }:
let
  setup-browser-cac = pkgs.writeShellApplication {
    name = "setup-browser-CAC";

    runtimeInputs = with pkgs; [
      nssTools
    ];

    runtimeEnv.OPENSC_PKCS11 = "${pkgs.opensc}/lib/opensc-pkcs11.so";

    text = builtins.readFile ./setup-browser-cac;
  };
in
{
  home.packages = [ setup-browser-cac ];
}
