{ pkgs, ... }:
{
  imports = [
    ./tools/oath.nix
    ./tools/wf-recorder.nix
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
  modules = {
    ai.claude-cognitive.enable = true;
    ai.team-skills.enable = true;
    ai.superpowers.enable = true;
  };
  home.packages = with pkgs; [
    mpv
    gimp3
    unzip
    claude-code
    pavucontrol
    cloudflared
    openssl
    spotify
    libnotify
    yubioath-flutter
    signal-desktop
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
        *Sleep*) systemctl suspend-then-hibernate ;;
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
        { id = "iaalpfgpbocpdfblpnhhgllgbdbchmia"; } # Asciidoctor.js Live Preview
      ];
    };
    zsh.sessionVariables = {
      BROWSER = "brave";
      EDITOR = "vim";
    };
  };
  gtk = {
    iconTheme = {
      package = pkgs.colloid-icon-theme;
      name = "Colloid";
    };
  };
}
