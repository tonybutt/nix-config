{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.modules.hyprland.enable {
    home.packages = [ pkgs.yubikey-touch-detector ];

    systemd.user.services.yubikey-touch-detector = {
      Unit.Description = "YubiKey touch detector";
      Service = {
        ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "default.target" ];
    };
    services.mako.enable = true;
    services.mako.settings = {
      "default-timeout" = 5000;

      # Route Signal notifications to HDMI monitor
      "app-name=Signal" = {
        output = "HDMI-A-1";
      };
      "app-name=yubikey-touch-detector" = {
        "icon-path" = "${config.home.homeDirectory}/.nix-profile/share/icons/hicolor";
        "max-icon-size" = 128;
        "default-timeout" = 0;
        anchor = "center";
        layer = "overlay";
      };
    };
  };
}
