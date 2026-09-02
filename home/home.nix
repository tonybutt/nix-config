{ pkgs, ... }:
{
  imports = [
    ./tools/oath.nix
    ./tools/mp4-to-gif.nix
    ./tools/theme-switch.nix
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
  # Stylix sets home.pointerCursor but not its enable flag; home-manager
  # deprecated relying on that implicit activation. Drop once stylix does
  # this itself.
  home.pointerCursor.enable = true;
  modules = {
    ai.claude-cognitive.enable = true;
    ai.team-skills.enable = true;
    ai.superpowers.enable = true;
    ai.gitnexus.enable = true;
    slack-gov.enable = true;
    terminals.ghostty.enable = true;
  };
  home.packages = with pkgs; [
    nixpkgs-review
    mpv
    imv
    pokeget-rs
    gimp3
    unzip
    claude-code
    sox
    pavucontrol
    cloudflared
    openssl
    spotify
    libnotify
    yubioath-flutter
    signal-desktop
    ssm-session-manager-plugin
    trayscale
    pcsc-tools
    (pkgs.writeShellScriptBin "setup-browser-CAC" ''
      NSSDB="''${HOME}/.pki/nssdb"
      mkdir -p ''${NSSDB}

      ${pkgs.nssTools}/bin/modutil -force -dbdir sql:$NSSDB -add yubi-smartcard \
        -libfile ${pkgs.opensc}/lib/opensc-pkcs11.so
    '')
    (pkgs.writeShellScriptBin "launch-webapp" ''
      exec ${pkgs.brave}/bin/brave --app="$1" "''${@:2}"
    '')
    (pkgs.writeShellScriptBin "system-menu" ''
      choice=$(printf "󰌾  Lock\n󰤄  Sleep\n  Reboot\n󰐥  Shutdown\n󰗽  Logout" | ${pkgs.fuzzel}/bin/fuzzel --dmenu -p "System: ")
      case "$choice" in
        *Lock*) loginctl lock-session ;;
        *Sleep*) systemctl suspend-then-hibernate ;;
        *Reboot*) systemctl reboot ;;
        *Shutdown*) systemctl poweroff ;;
        *Logout*) hyprctl dispatch exit ;;
      esac
    '')
  ];

  programs = {
    obs-studio = {
      enable = true;
      # OBS should render on whichever GPU the compositor owns, not on the
      # session-wide offload target. Its frames arrive in host memory from the
      # capture device and have to be read back to host memory again for the
      # v4l2 virtual camera, so a discrete GPU pays a PCIe crossing at both ends
      # and the readback stalls the pipeline; the integrated GPU maps the same
      # DDR5 the frames already live in. Measured on atlas over the virtual-cam
      # path (1080p -> 720p NV12, upload + scale + readback), the 780M beats the
      # RX 7700S by ~5% -- and both clear 500fps against a 30fps requirement, so
      # the dGPU's shader throughput buys nothing here while keeping the card
      # awake for ~21W.
      #
      # Clearing the variables rather than naming a device keeps this correct on
      # every host: Mesa's EGL/Wayland fallback is the compositor's own device,
      # and on single-GPU machines there is nothing to clear.
      # Wrapped by symlink rather than overrideAttrs so the cached obs-studio
      # build is reused instead of recompiled. wrapOBS reads name, meta and
      # passthru off whatever it is handed, so carry those across.
      package = pkgs.symlinkJoin {
        name = "obs-studio-compositor-gpu";
        paths = [ pkgs.obs-studio ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        inherit (pkgs.obs-studio) meta;
        passthru = pkgs.obs-studio.passthru or { };
        postBuild = ''
          wrapProgram $out/bin/obs \
            --unset DRI_PRIME \
            --unset MESA_VK_DEVICE_SELECT

          grep -q 'unset DRI_PRIME' $out/bin/obs || {
            echo "obs render-device unset did not reach the wrapper" >&2
            exit 1
          }
        '';
      };
    };
    kitty.settings = {
      scrollback_lines = 100000;
      copy_on_select = "clipboard";
    };
    brave = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # privacy badger
        { id = "damfoaielhjgnodobkkikiaiikkklejb"; } # Gather Meetings
        { id = "nmgegmkaijcgdgkfjhlbbaoabldoaehj"; } # Gather 1.0 Meetings (Classic)
        { id = "iaalpfgpbocpdfblpnhhgllgbdbchmia"; } # Asciidoctor.js Live Preview
        { id = "callobklhcbilhphinckomhgkigmfocg"; } # Endpoint Verification (Google Workspace)
        { id = "jlmpjdjjbgclbocgajdjefcidcncaied"; } # daily.dev
      ];
    };
    zsh.sessionVariables = {
      BROWSER = "brave";
      EDITOR = "vim";
    };
  };
  # Lets the Endpoint Verification extension query device attributes (serial,
  # disk encryption) via the native helper provided by modules/nixos/endpoint-
  # verification; /opt path is a tmpfiles symlink into the nix store.
  xdg.configFile."BraveSoftware/Brave-Browser/NativeMessagingHosts/com.google.endpoint_verification.api_helper.json".text =
    builtins.toJSON {
      name = "com.google.endpoint_verification.api_helper";
      description = "Google Endpoint Verification API Helper";
      path = "/opt/google/endpoint-verification/bin/apihelper";
      type = "stdio";
      allowed_origins = [
        "chrome-extension://callobklhcbilhphinckomhgkigmfocg/"
      ];
    };

  gtk = {
    iconTheme = {
      package = pkgs.colloid-icon-theme;
      name = "Colloid";
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4 = {
      # theme is set by Stylix (gtk.gtk4.theme = config.gtk.theme)
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };
  };
}
