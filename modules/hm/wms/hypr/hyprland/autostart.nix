{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.hyprland;
  inherit (lib) mkIf;
  inherit (lib.generators) mkLuaInline;

  spotify = lib.getExe pkgs.spotify;
  # clear stale sentinel files before launching obs to suppress the
  # "OBS didn't shut down properly" dialog caused by fast shutdown
  # ref: https://obsproject.com/forum/threads/190590/
  obs = pkgs.writeShellScript "obs-clean-start" ''
    rm -rf ~/.config/obs-studio/.sentinel
    exec ${lib.getExe pkgs.obs-studio} "$@"
  '';
  slack = lib.getExe pkgs.slack;
  signal = lib.getExe pkgs.signal-desktop;
  brave = lib.getExe pkgs.brave;
  # Obsidian is single-instance: a second invocation hands its URI to the
  # already-running process over the Electron singleton socket. Fired before
  # that socket exists the two race into separate instances, so open the work
  # vault, wait for the socket to appear, then ask for the personal one.
  obsidian = pkgs.writeShellScript "obsidian-vaults" ''
    obsidian=${lib.getExe pkgs.obsidian}
    "$obsidian" "obsidian://open?vault=work" &
    for _ in $(seq 1 60); do
      [ -e "$HOME/.config/obsidian/SingletonSocket" ] && break
      sleep 0.5
    done
    exec "$obsidian" "obsidian://open?vault=projects"
  '';
in
{
  config = mkIf cfg.enable {
    # Autostart (formerly exec-once)
    wayland.windowManager.hyprland.settings.on = {
      _args = [
        "hyprland.start"
        (mkLuaInline ''
          function()
            hl.exec_cmd("hyprpaper")
            hl.exec_cmd("systemctl --user import-environment PATH && systemctl --user restart xdg-desktop-portal.service")
            hl.exec_cmd("${lib.getExe pkgs.networkmanagerapplet} --indicator")
            hl.exec_cmd("${lib.getExe pkgs.trayscale} --hide-window")
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
}
