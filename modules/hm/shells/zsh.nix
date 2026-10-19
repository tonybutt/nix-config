{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.shells;
  inherit (lib) mkIf mkEnableOption;
  inherit (config.lib.stylix) colors;

  # Map ANSI 256-color codes in p10k.zsh to Stylix base16 hex colors.
  # Two replacement types: FOREGROUND=NN → ='#RRGGBB' and inline %NNF → %F{#RRGGBB}.
  # Values are single-quoted to prevent zsh EXTENDED_GLOB expansion of '#'.
  p10kReplacements = [
    # Inline %NF codes (longer numbers first to avoid partial matches)
    {
      from = "%244F";
      to = "%F{#${colors.base03}}";
    }
    {
      from = "%196F";
      to = "%F{#${colors.base08}}";
    }
    {
      from = "%178F";
      to = "%F{#${colors.base0A}}";
    }
    {
      from = "%215F";
      to = "%F{#${colors.base09}}";
    }
    {
      from = "%76F";
      to = "%F{#${colors.base0B}}";
    }
    {
      from = "%70F";
      to = "%F{#${colors.base0B}}";
    }
    {
      from = "%39F";
      to = "%F{#${colors.base0C}}";
    }

    # FOREGROUND= assignments (descending to avoid partial matches)
    {
      from = "=244";
      to = "='#${colors.base03}'";
    }
    {
      from = "=220";
      to = "='#${colors.base0A}'";
    }
    {
      from = "=215";
      to = "='#${colors.base09}'";
    }
    {
      from = "=208";
      to = "='#${colors.base09}'";
    }
    {
      from = "=196";
      to = "='#${colors.base08}'";
    }
    {
      from = "=180";
      to = "='#${colors.base09}'";
    }
    {
      from = "=178";
      to = "='#${colors.base0A}'";
    }
    {
      from = "=172";
      to = "='#${colors.base09}'";
    }
    {
      from = "=168";
      to = "='#${colors.base08}'";
    }
    {
      from = "=166";
      to = "='#${colors.base09}'";
    }
    {
      from = "=161";
      to = "='#${colors.base08}'";
    }
    {
      from = "=160";
      to = "='#${colors.base08}'";
    }
    {
      from = "=135";
      to = "='#${colors.base0E}'";
    }
    {
      from = "=134";
      to = "='#${colors.base0E}'";
    }
    {
      from = "=130";
      to = "='#${colors.base09}'";
    }
    {
      from = "=129";
      to = "='#${colors.base0E}'";
    }
    {
      from = "=125";
      to = "='#${colors.base08}'";
    }
    {
      from = "=117";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=110";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=103";
      to = "='#${colors.base04}'";
    }
    {
      from = "=101";
      to = "='#${colors.base04}'";
    }
    {
      from = "=99";
      to = "='#${colors.base0E}'";
    }
    {
      from = "=96";
      to = "='#${colors.base0E}'";
    }
    {
      from = "=94";
      to = "='#${colors.base04}'";
    }
    {
      from = "=81";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=76";
      to = "='#${colors.base0B}'";
    }
    {
      from = "=74";
      to = "='#${colors.base0D}'";
    }
    {
      from = "=72";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=70";
      to = "='#${colors.base0B}'";
    }
    {
      from = "=68";
      to = "='#${colors.base0D}'";
    }
    {
      from = "=67";
      to = "='#${colors.base04}'";
    }
    {
      from = "=66";
      to = "='#${colors.base04}'";
    }
    {
      from = "=39";
      to = "='#${colors.base0D}'";
    }
    {
      from = "=38";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=37";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=35";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=34";
      to = "='#${colors.base0C}'";
    }
    {
      from = "=33";
      to = "='#${colors.base0D}'";
    }
    {
      from = "=32";
      to = "='#${colors.base0D}'";
    }
    {
      from = "=31";
      to = "='#${colors.base0D}'";
    }
  ];

  p10kConfig = builtins.replaceStrings (map (r: r.from) p10kReplacements) (map (
    r: r.to
  ) p10kReplacements) (builtins.readFile ./p10k.zsh);
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
          src = pkgs.writeTextDir "p10k.zsh" p10kConfig;
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
        extended = true;
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
          # exec (not source) so the shell re-evaluates cleanly: no duplicated
          # PATH entries, no p10k instant-prompt complaints
          reload = "exec zsh";
          gct = "git commit";
          wk = "PJ_VAULT=$HOME/workspace/work pj";
          ts-login = "sudo tailscale up --login-server=https://headscale.tiberius.com --operator=$USER";
        }
        // lib.optionalAttrs (config.modules.themes.fastfetchLogoType == "pokeget") {
          fastfetch = "pokeget random --hide-name | ${lib.getExe pkgs.fastfetch} --logo-type file-raw --logo -";
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
