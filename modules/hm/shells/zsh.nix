{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.shells;
  inherit (lib) mkIf mkEnableOption;
in
{
  options = {
    modules.shells.zsh.enable = mkEnableOption "Enable zsh" // {
      default = true;
    };
  };
  config = mkIf cfg.zsh.enable {
    programs.zsh = {
      dotDir = "${config.xdg.configHome}/zsh";
      plugins = [
        {
          file = "p10k.zsh";
          src = ./.;
          name = "powerlevel10k-config";
        }
        {
          name = "zsh-powerlevel10k";
          src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
          file = "powerlevel10k.zsh-theme";
        }
      ];
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
          upd = "nh home switch ${flakeDir} --update";
          zed = "zeditor";
          gct = "git commit";
        };
      historySubstringSearch.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "helm"
          "kubectl"
          "docker"
          "docker-compose"
          "alias-finder"
          "z"
        ];
      };
    };

  };
}
