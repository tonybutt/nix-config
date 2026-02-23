{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules;
in
{
  config = mkIf cfg.laptop {
    # Default: clamshell-safe — lid close while docked/on external power does nothing.
    # Boot into the "on-the-go" specialisation when using the laptop as a laptop.
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };

    specialisation = {
      on-the-go.configuration = {
        services.logind.settings.Login = {
          HandleLidSwitchDocked = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
        };
      };
    };
  };
}
