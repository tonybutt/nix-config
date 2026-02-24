{
  pkgs,
  config,
  lib,
  user,
  inputs,
  ...
}:
with lib;
let
  cfg = config.modules.hyprland;
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
  session = "start-hyprland";
in
{
  options = {
    modules.hyprland.enable = mkEnableOption "Enable hyprland module" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    services = {
      greetd = {
        enable = true;
        settings = {
          initial_session = {
            command = "${session}";
            user = "${user.username}";
          };
          default_session = {
            command = "${tuigreet} --greeting 'Welcome to NixOS!' --asterisks --time --remember --remember-user-session -cmd ${session}";
            user = "${user.username}";
          };
        };
      };
      xserver = {
        enable = true;
        xkb.layout = "us";
      };
    };
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal"; # Without this errors will spam on screen
      # Without these bootlogs will spam on screen
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
    nix.settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };
    xdg.portal = {
      enable = true;
      config.common.default = [ "hyprland" ];
    };
    hardware = {
      nvidia = {
        open = true;
        powerManagement.enable = true;
      };
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
