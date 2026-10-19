{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkOption types;
  inherit (builtins) toString;

  # Hyprland 0.56 mode strings accept one preference keyword or WxH@r
  buildMode =
    m:
    if builtins.isAttrs m.resolution then
      "${toString m.resolution.width}x${toString m.resolution.height}@${toString m.resolution.refreshRate}"
    else if m.width != null && m.height != null then
      # Backwards compatibility
      "${toString m.width}x${toString m.height}@${
        toString (if m.refreshRate != null then m.refreshRate else 60)
      }"
    else if lib.hasPrefix "highres" m.resolution then
      "highres"
    else
      m.resolution;

  mkMonitor =
    m:
    {
      output = m.name;
    }
    // (
      if !m.enabled then
        { disabled = true; }
      else
        {
          mode = buildMode m;
          position = m.position;
          scale = m.scale;
        }
        // lib.optionalAttrs m.transform { transform = 1; }
    );
in
{
  options.modules.hyprland.monitors = mkOption {
    type = types.listOf (
      types.submodule {
        options = {
          transform = mkOption {
            type = types.bool;
            default = false;
          };
          name = mkOption {
            type = types.str;
            example = "DP-1";
          };

          resolution = mkOption {
            type = types.either types.str (
              types.submodule {
                options = {
                  width = mkOption {
                    type = types.int;
                    example = 1920;
                  };
                  height = mkOption {
                    type = types.int;
                    example = 1080;
                  };
                  refreshRate = mkOption {
                    type = types.int;
                    default = 60;
                  };
                };
              }
            );
            default = "preferred";
            example = "highres";
            description = ''
              Monitor resolution. Can be:
              - "highres" - Highest resolution
              - "highrr" - Highest refresh rate
              - "preferred" - Use monitor's preferred mode
              - { width = 1920; height = 1080; refreshRate = 60; } - Explicit resolution
              Legacy "highres@highrr"/"highres@high" values map to "highres"
              (Hyprland 0.56 mode strings accept a single preference).
            '';
          };

          # DEPRECATED: Keep for backwards compatibility
          width = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
          height = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
          refreshRate = mkOption {
            type = types.nullOr types.int;
            default = null;
          };

          scale = mkOption {
            type = types.str;
            default = "1";
          };
          position = mkOption {
            type = types.str;
            default = "auto";
          };
          enabled = mkOption {
            type = types.bool;
            default = true;
          };
          workspace = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };
      }
    );
    default = [ ];
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.monitor = (map mkMonitor cfg.monitors) ++ [
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "1";
      }
    ];
  };
}
