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
  p10kConfig =
    builtins.replaceStrings
      [
        # Inline %NF codes (longer numbers first to avoid partial matches)
        "%244F"
        "%196F"
        "%178F"
        "%215F"
        "%76F"
        "%70F"
        "%39F"
        # FOREGROUND= assignments (descending to avoid partial matches)
        "=244"
        "=220"
        "=215"
        "=208"
        "=196"
        "=180"
        "=178"
        "=172"
        "=168"
        "=166"
        "=161"
        "=160"
        "=135"
        "=134"
        "=130"
        "=129"
        "=125"
        "=117"
        "=110"
        "=103"
        "=101"
        "=99"
        "=96"
        "=94"
        "=81"
        "=76"
        "=74"
        "=72"
        "=70"
        "=68"
        "=67"
        "=66"
        "=39"
        "=38"
        "=37"
        "=35"
        "=34"
        "=33"
        "=32"
        "=31"
      ]
      [
        # Inline → %F{#RRGGBB}
        "%F{#${colors.base03}}"
        "%F{#${colors.base08}}"
        "%F{#${colors.base0A}}"
        "%F{#${colors.base09}}"
        "%F{#${colors.base0B}}"
        "%F{#${colors.base0B}}"
        "%F{#${colors.base0C}}"
        # FOREGROUND → ='#RRGGBB'
        #       244=chrome  220=yellow  215=orange  208=orange  196=red     180=orange  178=yellow  172=orange
        "='#${colors.base03}'"
        "='#${colors.base0A}'"
        "='#${colors.base09}'"
        "='#${colors.base09}'"
        "='#${colors.base08}'"
        "='#${colors.base09}'"
        "='#${colors.base0A}'"
        "='#${colors.base09}'"
        #       168=red     166=orange  161=red     160=red     135=purple  134=purple  130=orange  129=purple
        "='#${colors.base08}'"
        "='#${colors.base09}'"
        "='#${colors.base08}'"
        "='#${colors.base08}'"
        "='#${colors.base0E}'"
        "='#${colors.base0E}'"
        "='#${colors.base09}'"
        "='#${colors.base0E}'"
        #       125=red     117=cyan    110=cyan    103=muted   101=muted   99=purple   96=purple   94=muted
        "='#${colors.base08}'"
        "='#${colors.base0C}'"
        "='#${colors.base0C}'"
        "='#${colors.base04}'"
        "='#${colors.base04}'"
        "='#${colors.base0E}'"
        "='#${colors.base0E}'"
        "='#${colors.base04}'"
        #       81=cyan     76=green    74=blue     72=cyan     70=green    68=blue     67=muted    66=muted
        "='#${colors.base0C}'"
        "='#${colors.base0B}'"
        "='#${colors.base0D}'"
        "='#${colors.base0C}'"
        "='#${colors.base0B}'"
        "='#${colors.base0D}'"
        "='#${colors.base04}'"
        "='#${colors.base04}'"
        #       39=blue     38=cyan     37=cyan     35=cyan     34=cyan     33=blue     32=blue     31=blue
        "='#${colors.base0D}'"
        "='#${colors.base0C}'"
        "='#${colors.base0C}'"
        "='#${colors.base0C}'"
        "='#${colors.base0C}'"
        "='#${colors.base0D}'"
        "='#${colors.base0D}'"
        "='#${colors.base0D}'"
      ]
      (builtins.readFile ./p10k.zsh);
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
