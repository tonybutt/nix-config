{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  cfg = config.modules.peripherals;
  inherit (lib)
    mkIf
    mkEnableOption
    mkMerge
    optional
    optionalString
    concatLines
    ;
in
{
  options = {
    modules.peripherals.enable = mkEnableOption "Enable peripheral configuration" // {
      default = true;
    };
    modules.peripherals.obs.enable = mkEnableOption "Enable OBS virtual camera";
    modules.peripherals.scarlettRite.enable = mkEnableOption "Enable Scarlett Rite";
    modules.peripherals.openrazer.enable = mkEnableOption "Enable OpenRazer for Razer peripherals";
  };
  config = mkIf cfg.enable (mkMerge [
    {
      boot = {
        kernelModules = mkIf cfg.obs.enable (
          [ "v4l2loopback" ] ++ optional cfg.scarlettRite.enable "snd_aloop"
        );
        extraModulePackages = mkIf cfg.obs.enable [ config.boot.kernelPackages.v4l2loopback.out ];
        extraModprobeConfig = concatLines [
          (optionalString cfg.obs.enable ''
            options v4l2loopback devices=1 video_nr=1 card_label="Virtual Camera" exclusive_caps=1
          '')
          (optionalString cfg.scarlettRite.enable ''
            options snd_usb_audio vid=0x1235 pid=0x8212 device_setup=1
          '')
        ];
      };
    }
    (mkIf cfg.openrazer.enable {
      hardware.openrazer = {
        enable = true;
        users = [ user.username ];
      };
      environment.systemPackages = [ pkgs.polychromatic ];
    })
  ]);
}
