{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.generators) mkLuaInline;
  inherit (builtins) map toString toJSON;

  # Binary paths
  term = "${pkgs.ghostty}/bin/ghostty";
  thunar = "${pkgs.thunar}/bin/thunar";
  fuzzel = "${pkgs.fuzzel}/bin/fuzzel";
  cliphist = "${pkgs.cliphist}/bin/cliphist";
  wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  grim = "${pkgs.grim}/bin/grim";
  slurp = "${pkgs.slurp}/bin/slurp";
  swappy = "${pkgs.swappy}/bin/swappy";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  btop = "${pkgs.btop}/bin/btop";
  # Monitor scratchpad: btop for the system plus amdgpu_top for per-GPU
  # detail — mainly to watch the Navi 33 while the session offloads to it.
  monitors = pkgs.writeShellScript "monitor-scratchpad" ''
    ${term} -e ${btop} &
    exec ${term} -e ${pkgs.amdgpu_top}/bin/amdgpu_top
  '';
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  spotify = "${pkgs.spotify}/bin/spotify";
  # clear stale sentinel files before launching obs to suppress the
  # "OBS didn't shut down properly" dialog caused by fast shutdown
  # ref: https://obsproject.com/forum/threads/190590/
  obs = pkgs.writeShellScript "obs-clean-start" ''
    rm -rf ~/.config/obs-studio/.sentinel
    exec ${pkgs.obs-studio}/bin/obs "$@"
  '';
  slack = "${pkgs.slack}/bin/slack";
  signal = "${pkgs.signal-desktop}/bin/signal-desktop";
  brave = "${pkgs.brave}/bin/brave";
  # Obsidian is single-instance: a second invocation hands its URI to the
  # already-running process over the Electron singleton socket. Fired before
  # that socket exists the two race into separate instances, so open the work
  # vault, wait for the socket to appear, then ask for the personal one.
  obsidian = pkgs.writeShellScript "obsidian-vaults" ''
    obsidian=${pkgs.obsidian}/bin/obsidian
    "$obsidian" "obsidian://open?vault=work" &
    for _ in $(seq 1 60); do
      [ -e "$HOME/.config/obsidian/SingletonSocket" ] && break
      sleep 0.5
    done
    exec "$obsidian" "obsidian://open?vault=projects"
  '';
  gatherUrl = "https://work.tiberius.com";

  mod = cfg.mainMod;

  # hl.bind(combo, dispatcher [, opts]) — dispatcher factories must be raw Lua
  bind' = combo: dsp: {
    _args = [
      combo
      (mkLuaInline dsp)
    ];
  };
  bindOpts = combo: dsp: opts: {
    _args = [
      combo
      (mkLuaInline dsp)
      opts
    ];
  };
  execBind = combo: cmd: bind' combo "hl.dsp.exec_cmd(${toJSON cmd})";
  execBindOpts =
    combo: cmd: opts:
    bindOpts combo "hl.dsp.exec_cmd(${toJSON cmd})" opts;
in
{
  options = {
    modules.hyprland.enable = mkEnableOption "Enable hyprland window Manager" // {
      default = true;
    };
    modules.hyprland.monitors = mkOption {
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
    modules.hyprland.mainMod = mkOption {
      type = types.str;
      default = "SUPER";
      example = "CTRL";
      description = "The main modifier key for Hyprland bindings.";
    };
  };
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      # Hyprland 0.56+ resolves only ~/.config/hypr/hyprland.lua; the
      # hyprlang main config is gone upstream, so generate the Lua DSL.
      configType = "lua";
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      systemd = {
        enable = true;
        variables = [ "--all" ];
      };
      settings =
        let
          inherit (config.lib.stylix) colors;
          isDark = config.modules.themes.polarity == "dark";
          rgb = color: "rgb(${color})";
          activeGradient = {
            colors = [
              (rgb colors.base0B)
              (rgb colors.base0A)
            ];
            angle = 45;
          };
          inactiveGradient = rgb colors.base00;

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

          # workspace/movetoworkspacesilent binds for 1-10 (key 0 = ws 10)
          workspaceBinds = lib.concatMap (
            i:
            let
              key = toString (lib.mod i 10);
            in
            [
              (bind' "${mod} + ${key}" "hl.dsp.focus({ workspace = ${toString i} })")
              (bind' "${mod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${toString i}, follow = false })")
            ]
          ) (lib.range 1 10);
        in
        {
          env = [
            # Cursor size
            {
              _args = [
                "XCURSOR_SIZE"
                "24"
              ];
            }
            {
              _args = [
                "HYPRCURSOR_SIZE"
                "24"
              ];
            }
            # Force all apps to use Wayland
            {
              _args = [
                "GDK_BACKEND"
                "wayland,x11,*"
              ];
            }
            {
              _args = [
                "QT_QPA_PLATFORM"
                "wayland;xcb"
              ];
            }
            {
              _args = [
                "QT_STYLE_OVERRIDE"
                "kvantum"
              ];
            }
            {
              _args = [
                "SDL_VIDEODRIVER"
                "wayland"
              ];
            }
            {
              _args = [
                "MOZ_ENABLE_WAYLAND"
                "1"
              ];
            }
            {
              _args = [
                "ELECTRON_OZONE_PLATFORM_HINT"
                "wayland"
              ];
            }
            {
              _args = [
                "OZONE_PLATFORM"
                "wayland"
              ];
            }
            {
              _args = [
                "XDG_SESSION_TYPE"
                "wayland"
              ];
            }
            # Screen sharing support
            {
              _args = [
                "XDG_CURRENT_DESKTOP"
                "Hyprland"
              ];
            }
            {
              _args = [
                "XDG_SESSION_DESKTOP"
                "Hyprland"
              ];
            }
            # XCompose file
            {
              _args = [
                "XCOMPOSEFILE"
                "~/.XCompose"
              ];
            }
          ];

          config = {
            xwayland = {
              force_zero_scaling = false;
            };

            cursor = {
              no_hardware_cursors = true;
              hide_on_key_press = true;
            };

            ecosystem = {
              no_update_news = true;
            };

            debug = {
              disable_logs = false;
            };

            # Omarchy input config
            input = {
              kb_layout = "us";
              kb_options = "compose:caps";
              repeat_rate = 40;
              repeat_delay = 600;
              numlock_by_default = true;
              follow_mouse = 1;
              sensitivity = 0;

              touchpad = {
                natural_scroll = false;
                scroll_factor = 0.4;
              };
            };

            # Omarchy look and feel
            # String "col.*" keys intentionally mirror stylix's, so mkForce
            # overrides its target values instead of adding parallel keys
            general = {
              "col.active_border" = lib.mkForce activeGradient;
              "col.inactive_border" = lib.mkForce inactiveGradient;
              gaps_in = 3;
              gaps_out = 6;
              border_size = 2;
              resize_on_border = false;
              allow_tearing = false;
              layout = "dwindle";
            };

            decoration = {
              rounding = 6;

              shadow = {
                enabled = false;
                range = 2;
                render_power = 3;
              };

              blur = {
                enabled = true;
                size = 6;
                passes = 3;
                special = false;
                brightness = 0.80;
                contrast = 0.90;
                new_optimizations = true;
                ignore_opacity = true;
              };
            };

            animations = {
              enabled = true;
            };

            dwindle = {
              preserve_split = true;
              force_split = 2; # Always split on the right
            };

            master = {
              new_status = "master";
            };

            group = {
              "col.border_active" = lib.mkForce activeGradient;
              "col.border_inactive" = lib.mkForce inactiveGradient;
              "col.border_locked_active" = lib.mkForce activeGradient;
              "col.border_locked_inactive" = lib.mkForce inactiveGradient;

              groupbar = {
                font_size = 12;
                font_family = "monospace";
                font_weight_active = "ultraheavy";
                font_weight_inactive = "normal";
                indicator_height = 0;
                indicator_gap = 5;
                height = 22;
                gaps_in = 5;
                gaps_out = 0;
                text_color = lib.mkForce (rgb (if isDark then colors.base00 else colors.base07));
                text_color_inactive = lib.mkForce (rgb (if isDark then colors.base04 else colors.base02));
                "col.active" = lib.mkForce (rgb colors.base0B);
                "col.inactive" = lib.mkForce (rgb (if isDark then colors.base02 else colors.base05));
                gradients = true;
                gradient_rounding = 0;
                gradient_round_only_edges = false;
              };
            };

            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              focus_on_activate = true;
              anr_missed_pings = 3;
              on_focus_under_fullscreen = 1;
              key_press_enables_dpms = true;
              mouse_move_enables_dpms = true;
            };
          };

          # Omarchy animation curves
          curve = [
            {
              _args = [
                "easeOutQuint"
                {
                  type = "bezier";
                  points = [
                    [
                      0.23
                      1
                    ]
                    [
                      0.32
                      1
                    ]
                  ];
                }
              ];
            }
            {
              _args = [
                "easeInOutCubic"
                {
                  type = "bezier";
                  points = [
                    [
                      0.65
                      0.05
                    ]
                    [
                      0.36
                      1
                    ]
                  ];
                }
              ];
            }
            {
              _args = [
                "linear"
                {
                  type = "bezier";
                  points = [
                    [
                      0
                      0
                    ]
                    [
                      1
                      1
                    ]
                  ];
                }
              ];
            }
            {
              _args = [
                "almostLinear"
                {
                  type = "bezier";
                  points = [
                    [
                      0.5
                      0.5
                    ]
                    [
                      0.75
                      1.0
                    ]
                  ];
                }
              ];
            }
            {
              _args = [
                "quick"
                {
                  type = "bezier";
                  points = [
                    [
                      0.15
                      0
                    ]
                    [
                      0.1
                      1
                    ]
                  ];
                }
              ];
            }
          ];

          # Omarchy animations
          animation = [
            {
              leaf = "global";
              enabled = true;
              speed = 10;
              bezier = "default";
            }
            {
              leaf = "border";
              enabled = true;
              speed = 5.39;
              bezier = "easeOutQuint";
            }
            {
              leaf = "windows";
              enabled = true;
              speed = 4.79;
              bezier = "easeOutQuint";
            }
            {
              leaf = "windowsIn";
              enabled = true;
              speed = 4.1;
              bezier = "easeOutQuint";
              style = "popin 87%";
            }
            {
              leaf = "windowsOut";
              enabled = true;
              speed = 1.49;
              bezier = "linear";
              style = "popin 87%";
            }
            {
              leaf = "fadeIn";
              enabled = true;
              speed = 1.73;
              bezier = "almostLinear";
            }
            {
              leaf = "fadeOut";
              enabled = true;
              speed = 1.46;
              bezier = "almostLinear";
            }
            {
              leaf = "fade";
              enabled = true;
              speed = 3.03;
              bezier = "quick";
            }
            {
              leaf = "layers";
              enabled = true;
              speed = 3.81;
              bezier = "easeOutQuint";
            }
            {
              leaf = "layersIn";
              enabled = true;
              speed = 4;
              bezier = "easeOutQuint";
              style = "fade";
            }
            {
              leaf = "layersOut";
              enabled = true;
              speed = 1.5;
              bezier = "linear";
              style = "fade";
            }
            {
              leaf = "fadeLayersIn";
              enabled = true;
              speed = 1.79;
              bezier = "almostLinear";
            }
            {
              leaf = "fadeLayersOut";
              enabled = true;
              speed = 1.39;
              bezier = "almostLinear";
            }
            {
              leaf = "workspaces";
              enabled = false;
            }
          ];

          monitor = (map mkMonitor cfg.monitors) ++ [
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = "1";
            }
          ];

          gesture = [
            {
              fingers = 3;
              direction = "horizontal";
              action = "workspace";
            }
          ];

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

          # Tiling bindings (Omarchy + personal vim keys)
          bind = [
            # Close windows
            (bind' "${mod} + Q" "hl.dsp.window.close()")
            # Control tiling
            (bind' "${mod} + S" ''hl.dsp.layout("togglesplit")'')
            (bind' "${mod} + P" "hl.dsp.window.pseudo()")
            (bind' "${mod} + F" "hl.dsp.window.float()")
            (bind' "F11" "hl.dsp.window.fullscreen()")
            (bind' "${mod} + CTRL + F" "hl.dsp.window.fullscreen_state({ internal = 0, client = 2 })")
            (bind' "${mod} + ALT + F" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
            # Applications
            (execBind "${mod} + Return" term)
            (execBind "${mod} + E" thunar)
            (execBind "${mod} + SPACE" fuzzel)
            (execBind "${mod} + Y" "oath 22293570 19125157")
            (execBind "${mod} + V" "${cliphist} list | ${fuzzel} --dmenu | ${cliphist} decode | ${wl-copy}")
            # Web apps
            (execBind "${mod} + SHIFT + A" "launch-webapp https://chatgpt.com")
            (execBind "${mod} + SHIFT + G" "launch-webapp ${gatherUrl}")
            # Move focus with vim keys
            (bind' "${mod} + h" ''hl.dsp.focus({ direction = "left" })'')
            (bind' "${mod} + l" ''hl.dsp.focus({ direction = "right" })'')
            (bind' "${mod} + k" ''hl.dsp.focus({ direction = "up" })'')
            (bind' "${mod} + j" ''hl.dsp.focus({ direction = "down" })'')
            # Move focus with arrow keys
            (bind' "${mod} + LEFT" ''hl.dsp.focus({ direction = "left" })'')
            (bind' "${mod} + RIGHT" ''hl.dsp.focus({ direction = "right" })'')
            (bind' "${mod} + UP" ''hl.dsp.focus({ direction = "up" })'')
            (bind' "${mod} + DOWN" ''hl.dsp.focus({ direction = "down" })'')
            # Move/swap windows with vim keys (group-aware = movewindoworgroup)
            (bind' "${mod} + SHIFT + h" ''hl.dsp.window.move({ direction = "left", group_aware = true })'')
            (bind' "${mod} + SHIFT + l" ''hl.dsp.window.move({ direction = "right", group_aware = true })'')
            (bind' "${mod} + SHIFT + k" ''hl.dsp.window.move({ direction = "up", group_aware = true })'')
            (bind' "${mod} + SHIFT + j" ''hl.dsp.window.move({ direction = "down", group_aware = true })'')
            # Resize with vim keys
            (bind' "${mod} + CTRL + h" "hl.dsp.window.resize({ x = -60, y = 0, relative = true })")
            (bind' "${mod} + CTRL + l" "hl.dsp.window.resize({ x = 60, y = 0, relative = true })")
            (bind' "${mod} + CTRL + k" "hl.dsp.window.resize({ x = 0, y = -60, relative = true })")
            (bind' "${mod} + CTRL + j" "hl.dsp.window.resize({ x = 0, y = 60, relative = true })")
            # Special workspaces
            (bind' "${mod} + B" ''hl.dsp.workspace.toggle_special("browser")'')
            (bind' "${mod} + Z" ''hl.dsp.workspace.toggle_special("spotify")'')
            (bind' "${mod} + C" ''hl.dsp.workspace.toggle_special("chat")'')
            (bind' "${mod} + M" ''hl.dsp.workspace.toggle_special("monitor")'')
            (bind' "${mod} + O" ''hl.dsp.workspace.toggle_special("obs")'')
            (bind' "${mod} + N" ''hl.dsp.workspace.toggle_special("notes")'')
            # TAB between workspaces
            (bind' "${mod} + TAB" ''hl.dsp.focus({ workspace = "previous" })'')
            (bind' "${mod} + SHIFT + TAB" ''hl.dsp.focus({ workspace = "e-1" })'')
            (bind' "${mod} + CTRL + TAB" ''hl.dsp.focus({ workspace = "e+1" })'')
            # Move workspaces to other monitors
            (bind' "${mod} + SHIFT + ALT + LEFT" ''hl.dsp.workspace.move({ monitor = "l" })'')
            (bind' "${mod} + SHIFT + ALT + RIGHT" ''hl.dsp.workspace.move({ monitor = "r" })'')
            # Swap windows with arrows
            (bind' "${mod} + SHIFT + LEFT" ''hl.dsp.window.swap({ direction = "left" })'')
            (bind' "${mod} + SHIFT + RIGHT" ''hl.dsp.window.swap({ direction = "right" })'')
            (bind' "${mod} + SHIFT + UP" ''hl.dsp.window.swap({ direction = "up" })'')
            (bind' "${mod} + SHIFT + DOWN" ''hl.dsp.window.swap({ direction = "down" })'')
            # Resize active window
            (bind' "${mod} + minus" "hl.dsp.window.resize({ x = -100, y = 0, relative = true })")
            (bind' "${mod} + equal" "hl.dsp.window.resize({ x = 100, y = 0, relative = true })")
            (bind' "${mod} + SHIFT + minus" "hl.dsp.window.resize({ x = 0, y = -100, relative = true })")
            (bind' "${mod} + SHIFT + equal" "hl.dsp.window.resize({ x = 0, y = 100, relative = true })")
            # Scroll workspaces
            (bind' "${mod} + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
            (bind' "${mod} + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')
            # Groups
            (execBind "ALT + CTRL + SHIFT + L" "loginctl lock-session && ${hyprlock}")
            (bind' "${mod} + G" "hl.dsp.group.toggle()")
            (bind' "${mod} + ALT + G" "hl.dsp.window.move({ out_of_group = true })")
            (bind' "${mod} + ALT + J" "hl.dsp.group.next()")
            (bind' "${mod} + ALT + K" "hl.dsp.group.prev()")
            (bind' "${mod} + ALT + LEFT" ''hl.dsp.window.move({ into_group = "left" })'')
            (bind' "${mod} + ALT + RIGHT" ''hl.dsp.window.move({ into_group = "right" })'')
            (bind' "${mod} + ALT + UP" ''hl.dsp.window.move({ into_group = "up" })'')
            (bind' "${mod} + ALT + DOWN" ''hl.dsp.window.move({ into_group = "down" })'')
            (bind' "${mod} + ALT + TAB" "hl.dsp.group.next()")
            (bind' "${mod} + ALT + SHIFT + TAB" "hl.dsp.group.prev()")
            (bind' "${mod} + CTRL + LEFT" "hl.dsp.group.prev()")
            (bind' "${mod} + CTRL + RIGHT" "hl.dsp.group.next()")
            (bind' "${mod} + ALT + mouse_down" "hl.dsp.group.next()")
            (bind' "${mod} + ALT + mouse_up" "hl.dsp.group.prev()")
            # Group window by number
            (bind' "${mod} + ALT + 1" "hl.dsp.group.active({ index = 1 })")
            (bind' "${mod} + ALT + 2" "hl.dsp.group.active({ index = 2 })")
            (bind' "${mod} + ALT + 3" "hl.dsp.group.active({ index = 3 })")
            (bind' "${mod} + ALT + 4" "hl.dsp.group.active({ index = 4 })")
            (bind' "${mod} + ALT + 5" "hl.dsp.group.active({ index = 5 })")
            # Keyboard backlight
            (execBind "${mod} + F3" "${brightnessctl} -d *::kbd_backlight set +33%")
            (execBind "${mod} + F2" "${brightnessctl} -d *::kbd_backlight set 33%-")
            # Screenshot
            (execBind "Print" ''${grim} -g "$(${slurp})" - | ${swappy} -f -'')

            # ALT+TAB cycling (release binds, formerly bindr)
            (bindOpts "ALT + TAB" "hl.dsp.window.cycle_next()" { release = true; })
            (bindOpts "ALT + SHIFT + TAB" "hl.dsp.window.cycle_next({ next = false })" { release = true; })
            (bindOpts "ALT + TAB" "hl.dsp.window.bring_to_top()" { release = true; })
            (bindOpts "ALT + SHIFT + TAB" "hl.dsp.window.bring_to_top()" { release = true; })

            # Media keys (repeat on hold + locked, formerly bindel)
            (execBindOpts "XF86AudioRaiseVolume" "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+" {
              repeating = true;
              locked = true;
            })
            (execBindOpts "XF86AudioLowerVolume" "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-" {
              repeating = true;
              locked = true;
            })
            (execBindOpts "XF86AudioMute" "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle" {
              repeating = true;
              locked = true;
            })
            (execBindOpts "XF86AudioMicMute" "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle" {
              repeating = true;
              locked = true;
            })
            (execBindOpts "XF86MonBrightnessUp" "${brightnessctl} set 5%+" {
              repeating = true;
              locked = true;
            })
            (execBindOpts "XF86MonBrightnessDown" "${brightnessctl} set 5%-" {
              repeating = true;
              locked = true;
            })

            # Media playback (locked, formerly bindl)
            (execBindOpts "XF86AudioNext" "${playerctl} next" { locked = true; })
            (execBindOpts "XF86AudioPause" "${playerctl} play-pause" { locked = true; })
            (execBindOpts "XF86AudioPlay" "${playerctl} play-pause" { locked = true; })
            (execBindOpts "XF86AudioPrev" "${playerctl} previous" { locked = true; })

            # Mouse bindings (formerly bindm)
            (bindOpts "${mod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
            (bindOpts "${mod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
          ]
          ++ workspaceBinds;

          # Autostart (formerly exec-once)
          on = {
            _args = [
              "hyprland.start"
              (mkLuaInline ''
                function()
                  hl.exec_cmd("hyprpaper")
                  hl.exec_cmd("systemctl --user import-environment PATH && systemctl --user restart xdg-desktop-portal.service")
                  hl.exec_cmd("${pkgs.networkmanagerapplet}/bin/nm-applet --indicator")
                  hl.exec_cmd("${pkgs.trayscale}/bin/trayscale --hide-window")
                  hl.exec_cmd("${spotify}", { workspace = "special:spotify silent" })
                  hl.exec_cmd("${obs} --startvirtualcam", { workspace = "special:obs silent" })
                  hl.exec_cmd("${slack}", { workspace = "special:chat silent" })
                  hl.exec_cmd("${signal}", { workspace = "special:chat silent" })
                  hl.exec_cmd("${brave}", { workspace = "special:browser silent" })
                  hl.exec_cmd("${obsidian}", { workspace = "special:notes silent" })
                end'')
            ];
          };
        };
    };
  };
}
