{
  pkgs,
  ...
}:
{
  imports = [
    ./tools/oath.nix
  ];
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
    # {
    #   name = "DP-7";
    #   position = "auto-right";
    # }
    # {
    #   name = "DP-3";
    #   position = "auto-left";
    # }
  ];
  home.packages = with pkgs; [
    go
    pulumi-bin
    claude-code
    pavucontrol
    cloudflared
    rustup
    nodejs_23
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
    twofctl
    pcsc-tools
  ];

  programs = {
    nixcord.enable = true;
    nixcord.vesktop.enable = true;
    obs-studio.enable = true;
    foot.enable = true;
    chromium.enable = true;
    chromium.package = pkgs.brave;
    zsh.sessionVariables = {
      BROWSER = "firefox";
      EDITOR = "vim";
    };
    firefox.policies = {
      SecurityDevices = {
        Add = {
          "Yubikey/Smartcard" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
        };
      };
    };
    firefox.profiles.anthony = {
      bookmarks = {
        force = true;
        settings = [
          {
            name = "SSO Commercial";
            url = "https://d-9067aa9977.awsapps.com/start";
            tags = [ "work" ];
            keyword = "sso";
          }
        ];
      };
      extensions = {
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          vimium
          darkreader
          bitwarden
          privacy-badger
          ublock-origin
        ];
      };
      settings = {
        "ublock@raymondhill.net".settings = {
          selectedFilterLists = [
            "ublock-filters"
            "ublock-badware"
            "ublock-privacy"
            "ublock-unbreak"
            "ublock-quick-fixes"
          ];
        };
      };
    };
  };
  services.hyprpaper = {
    settings.preload = [
      "~/Wallpapers/Igris.png"
    ];
    settings.wallpaper = [
      "~/Wallpapers/Igris.png"
    ];
  };
  wayland.windowManager.hyprland = {
    settings = {
      workspace = [
        "special:spotify, on-created-empty: spotify"
        "special:obs, on-created-empty: obs"
        "special:chat, on-created-empty: slack; vesktop; signal-desktop"
        "special:browser, on-created-empty: firefox"
        "special:monitor, on-created-empty: foot btop"
      ];
      windowrule = [
        "float, title:^(Sign in to Security Device)$"
        "move 0 -60,title:^(app.gather.town is sharing your).*$"
        "float,title:^()$,class:^(dev.zed.Zed)$"
        "size 20% 20%,title:^()$,class:(dev.zed.Zed)"
        "move 0 0,title:^()$,class:(dev.zed.Zed)"
        "group,class:signal"
        "group,class:Slack"
        "group,class:vesktop"
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
        ", XF86AudioRaiseVolume, exec, pamixer -i 5 "
        ", XF86AudioLowerVolume, exec, pamixer -d 5 "
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86AudioMicMute, exec, pamixer --default-source -m"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%- "
        ", XF86MonBrightnessUp, exec, brightnessctl set +5% "
        '', Print, exec, grim -g "$(slurp)" - | swappy -f -''
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

}
