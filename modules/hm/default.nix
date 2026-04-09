{
  pkgs,
  lib,
  config,
  user,
  ...
}:
let
  c = config.lib.stylix.colors;
  toAnsi = base: "38;2;${c."${base}-rgb-r"};${c."${base}-rgb-g"};${c."${base}-rgb-b"}";
in
{
  imports = [
    ./wms
    ./git
    ./gpg
    ./editors
    ./shells
    ./terminals
    ./ssh
    ./ai
    ../stylix
  ];
  config = {
    stylix.targets.hyprlock.enable = lib.mkForce false;
    stylix.targets.hyprpaper.enable = lib.mkForce false;
    xdg = {
      enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/https" = [ "brave-browser.desktop" ];
          "x-scheme-handler/http" = [ "brave-browser.desktop" ];
          "text/html" = [ "brave-browser.desktop" ];
          "image/png" = [ "imv.desktop" ];
          "image/jpeg" = [ "imv.desktop" ];
          "image/gif" = [ "imv.desktop" ];
          "image/webp" = [ "imv.desktop" ];
          "image/bmp" = [ "imv.desktop" ];
          "image/tiff" = [ "imv.desktop" ];
          "image/svg+xml" = [ "imv.desktop" ];
        };
      };
    };
    home = {
      username = user.username;
      homeDirectory = "/home/${user.username}";
      packages = with pkgs; [
        # DevOpts
        awscli2
        kind
        fluxcd
        kubectl
        kubelogin-oidc
        kubernetes-helm
        kustomize
        istioctl
        cilium-cli
        vim

        # Shell Utils
        tree
        jq
        yubikey-manager

        # Clipboard
        grim
        slurp
        swappy
        wl-clipboard-rs

        # Dev Tools
        hyprpicker

        # Chat
        slack
      ];
      file."Wallpapers" = {
        recursive = true;
        source = ../stylix/assets/walls;
        target = "Wallpapers/Wallpapers/..";
      };
      stateVersion = "25.05";
    };
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
    };
    services.cliphist = {
      enable = true;
      allowImages = true;
    };
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        config.global.hide_env_diff = true;
      };
      btop.enable = true;
      fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      fastfetch = {
        enable = true;
        settings = {
          logo =
            if config.modules.themes.fastfetchLogoType == "pokeget" then
              {
                source = "-";
                type = "file-raw";
              }
            else if config.modules.themes.fastfetchLogo != null then
              {
                source = config.modules.themes.fastfetchLogo;
                type =
                  if config.modules.themes.fastfetchLogoType != null then
                    config.modules.themes.fastfetchLogoType
                  else
                    "auto";
              }
            else
              {
                source = "NixOS";
                color = {
                  "1" = toAnsi "base08";
                  "2" = toAnsi "base09";
                  "3" = toAnsi "base0D";
                  "4" = toAnsi "base0C";
                  "5" = toAnsi "base0B";
                  "6" = toAnsi "base0E";
                };
              };
          modules = [
            "title"
            "separator"
            "os"
            "host"
            "kernel"
            "uptime"
            "packages"
            "shell"
            "display"
            "wm"
            "terminal"
            "cpu"
            "gpu"
            "memory"
            "disk"
            "break"
            {
              type = "colors";
              symbol = "circle";
            }
          ];
        };
      };
    };
  };
}
