{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.secondfront.hyprland.enable {
    services.mako.enable = true;
    services.mako.settings = {
      "default-timeout" = 5000;
    };
  };
}
