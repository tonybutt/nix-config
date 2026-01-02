{
  pkgs,
  lib,
  user,
  ...
}:
{
  imports = [
    ./wms
    ./git
    ./gpg
    ./editors
    ./shells
    ./terminals
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
        };
      };
    };
    home = {
      username = user.name;
      homeDirectory = "/home/${user.name}";
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
      fastfetch.enable = true;
    };
  };
}
