{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./tools/oath.nix
    ./firefox.nix
    ../modules/hm
  ];
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color_scheme = "prefer-dark";
    };
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
  stylix = {
    targets.k9s.enable = true;
    cursor.package = pkgs.rose-pine-cursor;
    cursor.name = "BreezeX-RosePine-Linux";
    cursor.size = 24;
  };
  secondfront.hyprland.monitors = [
    {
      name = "eDP-1";
      enabled = false;
    }
    {
      name = "DP-6";
      position = "0x0";
      width = 2560;
      height = 1440;
      refreshRate = 60;
    }
  ];
  home.packages = with pkgs; [
    go
    gimp3
    pulumi-bin
    claude-code
    pavucontrol
    cloudflared
    rustup
    nodejs_24
    typescript
    gcc
    pkg-config
    rustls-libssl
    nodePackages.vscode-langservers-extracted
    openssl
    spotify
    libnotify
    yubioath-flutter
    nerd-fonts.jetbrains-mono
    signal-desktop
    stern
    discord
    uv
    ssm-session-manager-plugin
    pcsc-tools
    (pkgs.writeShellScriptBin "setup-browser-CAC" ''
      NSSDB="''${HOME}/.pki/nssdb"
      mkdir -p ''${NSSDB}

      ${pkgs.nssTools}/bin/modutil -force -dbdir sql:$NSSDB -add yubi-smartcard \
        -libfile ${pkgs.opensc}/lib/opensc-pkcs11.so
    '')
  ];

  programs = {
    zed-editor = {
      userSettings = {
        indent_guides = {
          enabled = true;
          coloring = "indent_aware";
          background_coloring = "indent_aware";
        };
      };
    };
    obs-studio.enable = true;
    kitty.settings = {
      scrollback_lines = 100000;
      copy_on_select = "clipboard";
    };
    chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # vimium
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # darkreader
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # privacy badger
      ];
    };
    zsh.sessionVariables = {
      BROWSER = "firefox";
      EDITOR = "vim";
    };
  };
  services.hyprpaper = {
    settings.preload = [
      "~/Wallpapers/Igris.png"
    ];
    settings.wallpaper = [
      ",~/Wallpapers/2fx.png"
    ];
  };
  gtk = {
    iconTheme = {
      package = pkgs.colloid-icon-theme;
      name = "Colloid";
    };
  };
  wayland.windowManager.hyprland = {
    settings = {
      group = {
        groupbar = {
          "col.inactive" = lib.mkForce "rgba(f5274e80)";
          "col.active" = lib.mkForce "rgba(3aff26bf)";
        };
      };
      workspace = [
        "special:spotify, on-created-empty: spotify"
        "special:obs, on-created-empty: nvidia-offload obs --startvirtualcam --disable-shutdown-check"
        "special:chat, on-created-empty: slack; signal-desktop;"
        "special:browser, on-created-empty: firefox"
        "special:monitor, on-created-empty: kitty btop"
      ];
      windowrule = [
        "float, title:^(MainPicker)$"
        "float, title:^(Sign in to Security Device)$"
        "workspace 10,title:^(app.gather.town is sharing)(.*)$"
        "float,title:^()$,class:^(dev.zed.Zed)$"
        "opacity 0.85,class:(dev.zed.Zed)"
        "group,class:signal"
        "group,class:Slack"
        "group,class:vesktop"
        "float,class:^(firefox)$,initialClass:"
        "float,class:^(dropdown)$"
        "size 800 400,class:^(dropdown)$"
        "center,class:^(dropdown)$"
        "animation slide,class:^(dropdown)$"
      ];
      exec-once = [
        "systemctl --user import-environment PATH && systemctl --user restart xdg-desktop-portal.service"
      ];
      bind = [
        "$mainMod, B, togglespecialworkspace, browser"
        "$mainMod, Z, togglespecialworkspace, spotify"
        "$mainMod, C, togglespecialworkspace, chat"
        "$mainMod, M, togglespecialworkspace, monitor"
        "$mainMod, O, togglespecialworkspace, obs"
        "$mainMod, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"
        "$mainMod, G, togglegroup"
        "$mainMod, Return, exec, nvidia-offload kitty"
        "$mainMod, Y, exec, oath 19125157"
        "$mainMod, Q, killactive,"
        "$mainMod, E, exec, thunar"
        "$mainMod, F, togglefloating,"
        "$mainMod, SPACE, exec, fuzzel"
        "$mainMod, P, pseudo, # dwindle"
        "$mainMod, S, togglesplit, # dwindle"
        "$mainMod, TAB, workspace, previous"
        ",F11,fullscreen"
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"
        "$mainMod ALT, J, changegroupactive, f"
        "$mainMod ALT, K, changegroupactive, b"
        "$mainMod SHIFT, h, movewindoworgroup, l"
        "$mainMod SHIFT, l, movewindoworgroup, r"
        "$mainMod SHIFT, k, movewindoworgroup, u"
        "$mainMod SHIFT, j, movewindoworgroup, d"
        "$mainMod CTRL, h, resizeactive, -60 0"
        "$mainMod CTRL, l, resizeactive,  60 0"
        "$mainMod CTRL, k, resizeactive,  0 -60"
        "$mainMod CTRL, j, resizeactive,  0  60"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod SHIFT, 0, movetoworkspacesilent, 10"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        "$mainMod, F3, exec, brightnessctl -d *::kbd_backlight set +33%"
        "$mainMod, F2, exec, brightnessctl -d *::kbd_backlight set 33%-"
        ", XF86AudioRaiseVolume, exec, ${pkgs.pamixer}/bin/pamixer -i 5 "
        ", XF86AudioLowerVolume, exec, ${pkgs.pamixer}/bin/pamixer -d 5 "
        ", XF86AudioMute, exec, ${pkgs.pamixer}/bin/pamixer -t"
        ", XF86AudioMicMute, exec, ${pkgs.pamixer}/bin/pamixer --default-source -m"
        ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%- "
        ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set +5% "
        '', Print, exec, grim -g "$(slurp)" - | swappy -f -''
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

}
