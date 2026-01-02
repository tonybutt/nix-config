{ pkgs, ... }:
{
  imports = [
    ./tools/oath.nix
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
  modules.hyprland.monitors = [
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
    unzip
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
    (pkgs.writeShellScriptBin "launch-webapp" ''
      exec ${pkgs.brave}/bin/brave --app="$1" "''${@:2}"
    '')
    (pkgs.writeShellScriptBin "system-menu" ''
      choice=$(printf "󰌾  Lock\n󰤄  Sleep\n  Reboot\n󰐥  Shutdown\n󰗽  Logout" | ${pkgs.fuzzel}/bin/fuzzel --dmenu -p "System: ")
      case "$choice" in
        *Lock*) loginctl lock-session ;;
        *Sleep*) systemctl suspend ;;
        *Reboot*) systemctl reboot ;;
        *Shutdown*) systemctl poweroff ;;
        *Logout*) hyprctl dispatch exit ;;
      esac
    '')
  ];

  programs = {
    obs-studio.enable = true;
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
      ];
    };
    zsh.sessionVariables = {
      BROWSER = "brave";
      EDITOR = "vim";
    };
  };
  modules.hyprpaper.wallpaper = "~/Wallpapers/Tiberius.png";
  gtk = {
    iconTheme = {
      package = pkgs.colloid-icon-theme;
      name = "Colloid";
    };
  };
}
