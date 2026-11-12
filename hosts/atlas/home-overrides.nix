{ lib, ... }:
let
  gatherUrl = "https://work.tiberius.com";
in
{
  modules.watchman.enable = true;

  # Open the Gather webapp when workspace 6 is created with no windows
  # (replaces the deprecated on_created_empty workspace rule)
  wayland.windowManager.hyprland.settings.on = [
    {
      _args = [
        "workspace.created"
        (lib.generators.mkLuaInline ''
          function(ws)
            if ws.id == 6 and ws.is_empty then
              hl.exec_cmd("launch-webapp ${gatherUrl}")
            end
          end'')
      ];
    }
  ];

  # Values are output names; an empty list means all outputs. [ "*" ] matches nothing.
  programs.waybar.settings.mainBar."hyprland/workspaces".persistent-workspaces = {
    "1" = [ ];
  };

  # Desktop workspace assignments
  wayland.windowManager.hyprland.settings.workspace_rule =
    let
      dell32 = "desc:Dell Inc. DELL S3220DGF BG9TF43";
      dell27 = "desc:Dell Inc. DELL U2718Q 4K8X703P0N8L";
      onMonitor = monitor: ws: {
        workspace = toString ws;
        inherit monitor;
      };
    in
    [
      (onMonitor dell32 1 // { default = true; })
      (onMonitor dell32 2)
      (onMonitor dell32 3)
      (onMonitor dell32 4)
      (onMonitor dell32 5)
      (onMonitor dell27 6 // { default = true; })
      (onMonitor dell27 7)
      (onMonitor dell27 8)
      (onMonitor dell27 9)
      (onMonitor dell27 10)
    ];

  modules = {
    hyprland.monitors = [
      # Laptop display enabled for travel; set enabled = false to turn it
      # off when docked. External monitor rules are inert while unplugged.
      {
        name = "eDP-2";
        resolution = "highres@highrr";
        scale = "1.25";
        enabled = false;
      }
      {
        name = "desc:Dell Inc. DELL S3220DGF BG9TF43";
        position = "0x0";
        resolution = "highres@highrr";
      }
      {
        name = "desc:Dell Inc. DELL U2718Q 4K8X703P0N8L";
        position = "auto-right";
        resolution = "highres@high";
      }
    ];
  };
}
