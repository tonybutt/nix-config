{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption;
  cfg = config.modules;
in
{
  options = {
    modules.extraDefaultPackages = mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional default packages to be installed in the system.";
    };
  };
  config = {
    environment.systemPackages =
      with pkgs;
      [
        kitty
        pavucontrol
        git
        vim
      ]
      ++ cfg.extraDefaultPackages;
  };
}
