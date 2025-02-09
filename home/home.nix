{
  pkgs,
  config,
  user,
  hyprland,
  lib,
  ...
}:
let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
  patched-opensc = pkgs.opensc.overrideAttrs (old: {
    version = "0.25.1";
    src = pkgs.fetchFromGitHub {
      owner = "OpenSC";
      repo = "OpenSC";
      rev = "0.25.1";
      sha256 = "sha256-Ktvp/9Hca87qWmDlQhFzvWsr7TvNpIAvOFS+4zTZbB8=";
    };
  });
  hypr-pkgs = hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ ../style ./tools/oath.nix ];
  stylix.targets.hyprlock.enable = false;
  home = {
    username = "${user.name}";
    homeDirectory = "/home/${user.name}";
    packages = with pkgs; [
      yubikey-manager
      libnotify
      yubioath-flutter
      nerd-fonts.jetbrains-mono
      grim
      slurp
      swappy
      wl-clipboard-rs
      hyprpicker
      patched-opensc
      vim
      signal-desktop
    ];
    stateVersion = "25.05";
  };

  services = {
    cliphist = {
      enable = true;
      allowImages = true;
    };
    mako = {
      enable = false;
      # Set timeout to 5 seconds
      defaultTimeout = 5000;
    };

    gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      enableZshIntegration = true;

      defaultCacheTtl = 1209600;
      defaultCacheTtlSsh = 1209600;
      maxCacheTtl = 1209600;
      maxCacheTtlSsh = 1209600;

      extraConfig = ''
        allow-preset-passphrase
      '';
    };
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global = {
          hide_env_diff = true;
        };
      };
    };
    zed-editor = {
      enable = true;
      extraPackages = [
        pkgs.nixd
        pkgs.nil
      ];
      extensions = [ "nix" "base16" "toml" "git-firefly" ];
      userSettings = {
        vim_mode = true;
        autosave = "on_focus_change";
        relative_line_numbers = true;
        project_panel = {
          dock = "right";
        };
        collaboration_panel = {
          dock = "right";
        };
        outline_panel = {
          dock = "right";
        };
      };
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      autocd = true;
      syntaxHighlighting.enable = true;
      history = {
        append = true;
      };
      shellAliases =
        let
          flakeDir = "$HOME/nix-config";
        in
        {
          rb = "nh os switch ${flakeDir}";
          rbh = "nh home switch ${flakeDir}";
        };
      historySubstringSearch.enable = true;
      oh-my-zsh = {
        theme = "robbyrussell";
        enable = true;
        plugins = [
          "git"
          "kubectl"
          "z"
        ];
      };
    };
    obs-studio.enable = true;
    btop.enable = true;
    fastfetch.enable = true;
    # Launcher
    fuzzel.enable = true;
    # Terminal
    foot = {
      enable = true;
    };
    kitty = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    # Signing
    gpg = {
      enable = true;
      scdaemonSettings = {
        reader-port = "Yubico Yubi";
        disable-ccid = true;
      };
      # Use an xdg-compliant directory for GnuPG. This
      # should generally work, but some programs still try
      # to create ~/.gnupg.
      homedir = "${config.home.homeDirectory}/.gnupg";

      settings = {
        # Default/trusted key ID to use (helpful with throw-keyids)
        default-key = user.signingkey;
        trusted-key = user.signingkey;

        keyserver = "hkps://keys.openpgp.org";

        # https://github.com/drduh/config/blob/master/gpg.conf
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html
        # Use AES256, 192, or 128 as cipher
        personal-cipher-preferences = "AES256 AES192 AES";
        # Use SHA512, 384, or 256 as digest
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        # Use ZLIB, BZIP2, ZIP, or no compression
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        # Default preferences for new keys
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        # SHA512 as digest to sign keys
        cert-digest-algo = "SHA512";
        # SHA512 as digest for symmetric ops
        s2k-digest-algo = "SHA512";
        # AES256 as cipher for symmetric ops
        s2k-cipher-algo = "AES256";
        # UTF-8 support for compatibility
        charset = "utf-8";
        # Show Unix timestamps
        fixed-list-mode = "";
        # No comments in messages
        no-comments = "";
        # No version in output
        no-emit-version = "";
        # Disable banner
        no-greeting = "";
        # Long hexadecimal key format
        keyid-format = "0xlong";
        # Display UID validity
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        # Display all keys and their fingerprints
        with-fingerprint = "";
        # Cross-certify subkeys are present and valid
        require-cross-certification = "";
        # Disable caching of passphrase for symmetrical ops
        no-symkey-cache = "";
        # Enable smartcard
        use-agent = "";
        # Output ASCII instead of binary
        armor = "";
        # Disable recipient key ID in messages (breaks Mailvelope)
        throw-keyids = "";
      };

      scdaemonSettings.deny-admin = true;
    };

    git = {
      package = pkgs.gitFull;
      enable = true;
      userName = user.name;
      userEmail = user.email;
      signing = {
        key = "~/.ssh/id_ed25519_sk.pub";
        signByDefault = true;
      };
      extraConfig = {
        gpg.format = "ssh";
        core.askPass = "";
        core.editor = "vim";
        init.defaultBranch = "main";
        credential.helper = "libsecret";
      };
    };

    # Browser
    firefox = {
      enable = true;
      languagePacks = [
        "de"
        "en-US"
      ];
      # ---- POLICIES ----
      # Check about:policies#documentation for options.
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
        DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
        SearchBar = "unified"; # alternative: "separate"

        # ---- EXTENSIONS ----
        # Check about:support for extension/add-on ID strings.
        # Valid strings for installation_mode are "allowed", "blocked",
        # "force_installed" and "normal_installed".
        ExtensionSettings = {
          "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          # Privacy Badger:
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
          # Bitwarden
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4387077/bitwarden_password_manager-2024.11.0.xpi";
            installation_mode = "force_installed";
          };
        };

        # ---- PREFERENCES ----
        # Check about:config for options.
        Preferences = {
          "browser.contentblocking.category" = {
            Value = "strict";
            Status = "locked";
          };
          "extensions.pocket.enabled" = lock-false;
          "extensions.screenshots.disabled" = lock-true;
          "browser.topsites.contile.enabled" = lock-false;
          "browser.formfill.enable" = lock-false;
          "browser.search.suggest.enabled" = lock-false;
          "browser.search.suggest.enabled.private" = lock-false;
          "browser.urlbar.suggest.searches" = lock-false;
          "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
          "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
          "browser.newtabpage.activity-stream.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
        };
      };
    };

    hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 0;
          hide_cursor = true;
        };

        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "250, 60";
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(0, 0, 0, 0.5)";
            font_color = "rgb(200, 200, 200)";
            fade_on_empty = false;
            font_family = "Fira Mono";
            placeholder_text = ''<i><span foreground="##cdd6f4">Input Password...</span></i>'';
            hide_input = false;
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
        ];
        label = [
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%-I:%M%p")"'';
            color = "rgba(255, 255, 255, 0.6)";
            font_size = 120;
            font_family = "Fira Mono";
            position = "0, -300";
            halign = "center";
            valign = "top";
          }
          {
            monitor = "";
            text = "Hi there, $USER";
            text_align = "center"; # center/right or any value for default left. multi-line text alignment inside label container
            color = "rgba(200, 200, 200, 1.0)";
            font_size = 25;
            font_family = "Fira Code";
            rotate = 0; # degrees, counter-clockwise

            position = "0, 80";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
  wayland.windowManager.hyprland = {
    enable = true;
    package = hypr-pkgs.hyprland;
    xwayland.enable = true;
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };
    settings = {
      "$mainMod" = "SUPER";

      monitor = [
        ",preferred,auto,1.5"
      ];
      xwayland = {
        force_zero_scaling = true;
      };

      cursor = {
        no_hardware_cursors = true;
      };

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XCURSOR_SIZE,36"
        "HYPRCURSOR_SIZE,24"
        "QT_QPA_PLATFORM,wayland"
        "XDG_SCREENSHOTS_DIR,~/screens"
      ];

      debug = {
        disable_logs = false;
        enable_stdout_logs = true;
      };

      input = {
        kb_layout = "us";
        numlock_by_default = true;
        follow_mouse = 1;

        touchpad = {
          natural_scroll = false;
        };

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };

      general = {
        gaps_in = 1;
        gaps_out = 5;
        border_size = 2;

        layout = "dwindle";
      };

      decoration = {
        rounding = 6;

        blur = {
          enabled = false;
          size = 16;
          passes = 2;
          new_optimizations = true;
        };
        shadow = lib.mkForce { };
      };

      animations = {
        enabled = true;

        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        # bezier = "myBezier, 0.33, 0.82, 0.9, -0.08";

        animation = [
          "windows,     1, 7,  myBezier"
          "windowsOut,  1, 7,  default, popin 80%"
          "border,      1, 10, default"
          "borderangle, 1, 8,  default"
          "fade,        1, 7,  default"
          "workspaces,  1, 6,  default"
        ];
      };

      dwindle = {
        pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # you probably want this
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
        workspace_swipe_invert = false;
        workspace_swipe_distance = 200;
        workspace_swipe_forever = true;
      };

      misc = {
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        enable_swallow = true;
        render_ahead_of_time = false;
        disable_hyprland_logo = true;
      };

      workspace = [
        "special:spotify"
        "special:obs"
        "special:chat"
        "special:browser"
      ];
      windowrule = [
        "float, ^(imv)$"
        "float, ^(mpv)$"
        "float, title:^(Sign in to Security Device)$"
        "move 0 -60,title:^(app.gather.town is sharing your).*$"
      ];
      windowrulev2 = [
        "float,title:^()$,class:^(dev.zed.Zed)$"
        "size 20% 20%,title:^()$,class:(dev.zed.Zed)"
        "move 0 0,title:^()$,class:(dev.zed.Zed)"
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "hyprpaper"
        "hypridle"
        "hyprpanel"
        "[workspace special:chat silent] slack"
        "[workspace special:chat silent] discord"
        "[workspace special:chat silent] signal-desktop"
        "[workspace special:browser silent] firefox"
        "[workspace 1 silent] hyprctl dispatch togglespecialworkspace chat"
      ];

      bind = [
        "$mainMod, B, togglespecialworkspace, browser"
        "$mainMod, Z, togglespecialworkspace, spotify"
        "$mainMod, C, togglespecialworkspace, chat"
        "$mainMod, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"
        "$mainMod, G, togglegroup"
        "$mainMod, Return, exec, foot"
        "$mainMod, Y, exec, ykmanoath"
        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, thunar"
        "$mainMod, F, togglefloating,"
        "$mainMod, SPACE, exec, fuzzel"
        "$mainMod, P, pseudo, # dwindle"
        "$mainMod, S, togglesplit, # dwindle"
        "$mainMod, TAB, workspace, previous"
        ",F11,fullscreen"

        # Move focus with mainMod + arrow keys
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"

        # Move tabs within group with vim motion
        "$mainMod ALT, J, changegroupactive, f"
        "$mainMod ALT, K, changegroupactive, b"

        # Moving windows
        "$mainMod SHIFT, h, movewindoworgroup, l"
        "$mainMod SHIFT, l, movewindoworgroup, r"
        "$mainMod SHIFT, k, movewindoworgroup, u"
        "$mainMod SHIFT, j, movewindoworgroup, d"

        # Window resizing                 X  Y
        "$mainMod CTRL, h, resizeactive, -60 0"
        "$mainMod CTRL, l, resizeactive,  60 0"
        "$mainMod CTRL, k, resizeactive,  0 -60"
        "$mainMod CTRL, j, resizeactive,  0  60"

        # Switch workspaces with mainMod + [0-9]
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

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
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

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Keyboard backlight
        "$mainMod, F3, exec, brightnessctl -d *::kbd_backlight set +33%"
        "$mainMod, F2, exec, brightnessctl -d *::kbd_backlight set 33%-"

        # Volume and Media Control
        ", XF86AudioRaiseVolume, exec, pamixer -i 5 "
        ", XF86AudioLowerVolume, exec, pamixer -d 5 "
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86AudioMicMute, exec, pamixer --default-source -m"

        # Brightness control
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%- "
        ", XF86MonBrightnessUp, exec, brightnessctl set +5% "

        # Configuration files
        '', Print, exec, grim -g "$(slurp)" - | swappy -f -''

        # Waybar
        "$mainMod, B, exec, pkill -SIGUSR1 waybar"
        "$mainMod, W, exec, pkill -SIGUSR2 waybar"

        # Disable all effects
      ];

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

}
