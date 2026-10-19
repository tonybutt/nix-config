{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkOption types;
  inherit (lib.generators) mkLuaInline;
  inherit (builtins) toString toJSON;

  term = lib.getExe pkgs.ghostty;
  thunar = lib.getExe pkgs.thunar;
  fuzzel = lib.getExe pkgs.fuzzel;
  cliphist = lib.getExe pkgs.cliphist;
  wl-copy = lib.getExe' pkgs.wl-clipboard "wl-copy";
  brightnessctl = lib.getExe pkgs.brightnessctl;
  grim = lib.getExe pkgs.grim;
  slurp = lib.getExe pkgs.slurp;
  swappy = lib.getExe pkgs.swappy;
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  playerctl = lib.getExe pkgs.playerctl;
  hyprlock = lib.getExe pkgs.hyprlock;
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
  options.modules.hyprland.mainMod = mkOption {
    type = types.str;
    default = "SUPER";
    example = "CTRL";
    description = "The main modifier key for Hyprland bindings.";
  };

  config = mkIf cfg.enable {
    # Tiling bindings (Omarchy + personal vim keys)
    wayland.windowManager.hyprland.settings.bind = [
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
  };
}
