{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  # Toggle mako's "screenshare" mode from Hyprland's screencast IPC
  # events (emitted when any screencopy/portal share starts or stops)
  makoScreenshareWatch = pkgs.writeShellScript "mako-screenshare-watch" ''
    sig="''${HYPRLAND_INSTANCE_SIGNATURE:-$(${pkgs.coreutils}/bin/ls -t "$XDG_RUNTIME_DIR/hypr" | ${pkgs.coreutils}/bin/head -n1)}"
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$sig/.socket2.sock" \
      | while IFS= read -r line; do
          case "$line" in
            "screencast>>1"*) ${config.services.mako.package}/bin/makoctl mode -a screenshare > /dev/null ;;
            "screencast>>0"*) ${config.services.mako.package}/bin/makoctl mode -r screenshare > /dev/null ;;
          esac
        done
  '';
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

    systemd.user.services.mako-screenshare-watch = {
      Unit = {
        Description = "Suppress messaging notifications while screensharing";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${makoScreenshareWatch}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    services.mako.enable = true;
    services.mako.settings = {
      "default-timeout" = 5000;
      # Match Hyprland decoration.rounding; bump text above stylix popups size
      "border-radius" = 6;
      font = lib.mkForce "${config.stylix.fonts.sansSerif.name} 16";
      # Defaults (300x100) clip content at font size 16; these are
      # maximums — short notifications still shrink to fit
      width = 450;
      height = 300;

      # Messaging apps show full content normally, but are suppressed
      # entirely while the screenshare mode is active (queued, not lost:
      # makoctl restore). Mode is driven by mako-screenshare-watch.
      "mode=screenshare app-name=Signal" = {
        invisible = 1;
      };
      "mode=screenshare app-name=Slack" = {
        invisible = 1;
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
