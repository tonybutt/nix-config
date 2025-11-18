{ config, lib, ... }:
with lib;
let
  cfg = config.modules.peripherals;
in
{
  options = {
    modules.peripherals.enable = mkEnableOption "Enable peripheral configuration" // {
      default = true;
    };
    modules.peripherals.obs.enable = mkEnableOption "Enable OBS virtual camera";
    modules.peripherals.scarlettRite.enable = mkEnableOption "Enable Scarlett Rite";
  };
  config = mkIf cfg.enable {
    boot = {

      kernelModules = mkIf cfg.obs.enable (
        [ "v4l2loopback" ] ++ (if cfg.scarlettRite.enable then [ "snd_aloop" ] else [ ])
      );
      extraModulePackages = mkIf cfg.obs.enable [ config.boot.kernelPackages.v4l2loopback.out ];
      extraModprobeConfig =
        (
          if cfg.obs.enable then
            ''
              options v4l2loopback devices=1 video_nr=1 card_label="Virtual Camera" exclusive_caps=1
            ''
          else
            ""
        )
        + (
          if cfg.scarlettRite.enable then
            ''
              options snd_usb_audio vid=0x1235 pid=0x8212 device_setup=1
            ''
          else
            ""
        );
    };
  };
}
