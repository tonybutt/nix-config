{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib) mkIf;

  term = lib.getExe pkgs.ghostty;
  # Monitor scratchpad: btop for the system plus amdgpu_top for per-GPU
  # detail — mainly to watch the Navi 33 while the session offloads to it.
  monitors = pkgs.writeShellScript "monitor-scratchpad" ''
    ${term} -e ${lib.getExe pkgs.btop} &
    exec ${term} -e ${lib.getExe pkgs.amdgpu_top}
  '';
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      # Special workspaces
      workspace_rule = [
        {
          workspace = "special:monitor";
          on_created_empty = "${monitors}";
        }
      ];

      # Omarchy window rules + personal rules; later rules win
      window_rule = [
        {
          match.title = "Select what to share";
          size = [
            250
            250
          ];
          float = true;
          center = true;
        }
        {
          match.class = ".*";
          suppress_event = "maximize";
        }
        # Blur only for terminals — disable globally then re-enable for terminals
        {
          match.class = ".*";
          no_blur = true;
        }
        {
          match.class = "(kitty|Alacritty|com.mitchellh.ghostty|dev.zed.Zed)";
          no_blur = false;
        }
        {
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }
        {
          match.class = "(Alacritty|kitty|com.mitchellh.ghostty)";
          scroll_touchpad = 1.5;
        }
        {
          match.class = "com.mitchellh.ghostty";
          scroll_touchpad = 0.2;
        }
        # Personal window rules
        {
          match.title = "^(MainPicker)$";
          float = true;
        }
        {
          match.title = "^(Sign in to Security Device)$";
          float = true;
        }
        # Browser routing: regular Brave -> browser special workspace, Gather webapp -> workspace 6
        {
          match.class = "^(brave-browser)$";
          workspace = "special:browser silent";
        }
        {
          match.class = "^(brave-(work\\.tiberius\\.com|app(\\.v2)?\\.gather\\.town).*)$";
          workspace = "6 silent";
        }
        # Screen-share indicator: must come after the brave class rules — later rules
        # win, so this keeps the popup out of special:browser/workspace 6
        {
          match.title = "^(.+ is sharing (your screen|a window|a tab))(.*)$";
          workspace = "10 silent";
        }
        # Bitwarden extension popups (nngc... is Bitwarden's extension id);
        # loose match catches any popup window the extension opens, any profile
        {
          match.class = ".*nngceckbapebfimnlniiiahkandclblb.*";
          float = true;
          center = true;
          size = [
            500
            "monitor_h*0.6"
          ];
        }
        # Obsidian reports class md.Obsidian, not obsidian — both vault
        # windows land on the notes scratchpad.
        {
          match.class = "^(md\\.Obsidian)$";
          workspace = "special:notes silent";
        }
        {
          match = {
            title = "^()$";
            class = "^(dev.zed.Zed)$";
          };
          float = true;
        }
        {
          match.class = "(dev.zed.Zed)";
          opacity = "0.85";
        }
        {
          match.class = "^(dropdown)$";
          float = true;
          size = [
            800
            400
          ];
          center = true;
          animation = "slide";
        }
        {
          match.class = "^(ssh-askpass)$";
          float = true;
          center = true;
          size = [
            400
            200
          ];
        }
        # Steam
        {
          match.class = "^(steam)$";
          float = true;
        }
        {
          # size expressions replace the old "80% 80%" percentage syntax
          match = {
            class = "^(steam)$";
            title = "^(Steam)$";
          };
          size = [
            "monitor_w*0.8"
            "monitor_h*0.8"
          ];
          center = true;
        }
        {
          match = {
            class = "^(steam)$";
            title = "^(Friends List)$";
          };
          size = [
            400
            600
          ];
        }
        {
          match = {
            class = "^(steam)$";
            title = "^(Steam Settings)$";
          };
          size = [
            800
            600
          ];
        }
        # Steam games
        {
          match.class = "^(steam_app_.*)$";
          fullscreen = true;
          no_blur = true;
          immediate = true;
        }
      ];
    };
  };
}
