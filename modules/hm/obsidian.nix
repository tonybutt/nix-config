{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.obsidian;
  inherit (lib) mkIf mkEnableOption;

  # Community plugins packaged from their GitHub release assets. The
  # home-manager programs.obsidian module reads manifest.json from each
  # package root, so every plugin is a directory of main.js/manifest.json/styles.css.
  mkObsidianPlugin =
    {
      pname,
      version,
      repo,
      hashes,
    }:
    let
      asset =
        name:
        pkgs.fetchurl {
          url = "https://github.com/${repo}/releases/download/${version}/${name}";
          hash = hashes.${name};
        };
    in
    pkgs.runCommandLocal "obsidian-plugin-${pname}-${version}" { } ''
      mkdir -p $out
      cp ${asset "main.js"} $out/main.js
      cp ${asset "manifest.json"} $out/manifest.json
      cp ${asset "styles.css"} $out/styles.css
    '';

  plugins = [
    (mkObsidianPlugin {
      pname = "templater";
      version = "2.24.0";
      repo = "SilentVoid13/Templater";
      hashes = {
        "main.js" = "sha256-A7dlSjAhrY7kP6/7FAyLTK8/xmsKMaBd1YUzwPhrfhI=";
        "manifest.json" = "sha256-MEFgXLIA8k9dNxzvhicOAHxuiqUoeOp0OHUVBRLImUM=";
        "styles.css" = "sha256-65QGO+YCZ585fj41/Lf2pLAn2oLhfCE7tEomfGtF2N4=";
      };
    })
    (mkObsidianPlugin {
      pname = "storyline";
      version = "1.10.47";
      repo = "PixeroJan/obsidian-storyline";
      hashes = {
        "main.js" = "sha256-CwbxkY1KyUpBCRn/jVAaKTh8OhnYeCs42sX3jAkUlbI=";
        "manifest.json" = "sha256-E4wPWM2LaxPXRGxW9uv8dAUK4FnLuyDDwVyad4dI90k=";
        "styles.css" = "sha256-e0+pWxlU8w+aadrZUSXz4ApLLBUk1t7387J1du0Hkio=";
      };
    })
    (mkObsidianPlugin {
      pname = "novel-word-count";
      version = "4.6.4";
      repo = "isaaclyman/novel-word-count-obsidian";
      hashes = {
        "main.js" = "sha256-hc27jeC71MFEubBfdEw9Y246oRRxfh++xGAG0i8XDqY=";
        "manifest.json" = "sha256-A+be2hcNPyHNBZws14SdMGVvU6LBAaT76O3+1IUIPKg=";
        "styles.css" = "sha256-N4ptHfv/05q2wVXmoTuZyNFPqmROMr4j23TZ3JUISrk=";
      };
    })
    (mkObsidianPlugin {
      pname = "auto-timelines";
      version = "0.14.1";
      repo = "April-Gras/obsidian-auto-timelines";
      hashes = {
        "main.js" = "sha256-kury5QNhjZkr+X2WetFeich7QheUorbnH9QqU8ujNT8=";
        "manifest.json" = "sha256-vQCA3KUTooIGgd0lAhAVuawJquFCEObUzKPFSJgd378=";
        "styles.css" = "sha256-0saKUtxDEHdry5uen5wPSj6q+qIt/TvNXanCowUn+mE=";
      };
    })
    (mkObsidianPlugin {
      pname = "excalidraw";
      version = "2.25.3";
      repo = "zsviczian/obsidian-excalidraw-plugin";
      hashes = {
        "main.js" = "sha256-aEz22kP247KnZG1aUNFPekPrXYWdBz3Go3XEobCZDdY=";
        "manifest.json" = "sha256-Q/GLwXxcP3avGppBkdqhw1ZuKHWqRDBWHVe3goeFKC4=";
        "styles.css" = "sha256-I2oRP+41gexZhWryLGzs95+vNSGvrmYiekD2/2zZiWk=";
      };
    })
  ];

  projectsPlugins = [
    (mkObsidianPlugin {
      pname = "dataview";
      version = "0.5.70";
      repo = "blacksmithgu/obsidian-dataview";
      hashes = {
        "main.js" = "sha256-a7HPcBCvrYMOc1dfyg4r+9MnnFYuPZ0k8tL0UWHrfQA=";
        "manifest.json" = "sha256-kjXbRxEtqBuFWRx57LmuJXTl5yIHBW6XZHL5BhYoYYU=";
        "styles.css" = "sha256-MwbdkDLgD5ibpyM6N/0lW8TT9DQM7mYXYulS8/aqHek=";
      };
    })
    (mkObsidianPlugin {
      pname = "tasks";
      version = "8.3.0";
      repo = "obsidian-tasks-group/obsidian-tasks";
      hashes = {
        "main.js" = "sha256-FwrAr0FggS/mxUErlhsiIql8VCOtl4pTgQnG0zIfD1I=";
        "manifest.json" = "sha256-y0LVY7vNX+VRABesA11wEwX8YGjK/YU4JX5UehZ/ljc=";
        "styles.css" = "sha256-2thMf5im6Q2Aruu1xlvnSb4xLwOEK1Ho9qAx6yLsnOI=";
      };
    })
  ];

  # Scaffolds a new story in the writing vault from a title and optional
  # premise. Never overwrites: refuses if the story folder exists and only
  # seeds vault-level Templater templates that are missing.
  newStory = pkgs.writeShellApplication {
    name = "new-story";
    text = builtins.readFile ./obsidian/new-story.sh;
  };

  colors = config.lib.stylix.colors.withHashtag;
  # Base16 -> Obsidian CSS variables. Follows the active Stylix theme, so
  # theme-switch restyles Obsidian along with everything else.
  stylixCss = ''
    .theme-dark,
    .theme-light {
      --background-primary: ${colors.base00};
      --background-primary-alt: ${colors.base01};
      --background-secondary: ${colors.base01};
      --background-secondary-alt: ${colors.base02};
      --background-modifier-border: ${colors.base02};
      --background-modifier-border-hover: ${colors.base03};
      --background-modifier-border-focus: ${colors.base0D};
      --text-normal: ${colors.base05};
      --text-muted: ${colors.base04};
      --text-faint: ${colors.base03};
      --text-accent: ${colors.base0D};
      --text-accent-hover: ${colors.base0C};
      --text-on-accent: ${colors.base00};
      --text-selection: ${colors.base02};
      --text-highlight-bg: ${colors.base02};
      --interactive-accent: ${colors.base0D};
      --interactive-accent-hover: ${colors.base0C};
      --link-color: ${colors.base0D};
      --link-color-hover: ${colors.base0C};
      --link-external-color: ${colors.base0C};
      --link-unresolved-color: ${colors.base08};
      --tag-color: ${colors.base0E};
      --code-normal: ${colors.base05};
      --code-background: ${colors.base01};
      --hr-color: ${colors.base02};
      --blockquote-border-color: ${colors.base0D};
      --h1-color: ${colors.base0D};
      --h2-color: ${colors.base0C};
      --h3-color: ${colors.base0B};
      --h4-color: ${colors.base0A};
      --h5-color: ${colors.base09};
      --h6-color: ${colors.base08};
    }
  '';
in
{
  options = {
    modules.obsidian.enable = mkEnableOption "Obsidian writing setup" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ newStory ];

    programs.obsidian = {
      enable = true;
      vaults.writing = {
        target = "Documents/writing";
        settings = {
          # Shipping cssSnippets pins appearance.json, so set its basics here.
          appearance = {
            theme = "obsidian";
            interfaceFontFamily = config.stylix.fonts.sansSerif.name;
            textFontFamily = config.stylix.fonts.sansSerif.name;
            monospaceFontFamily = config.stylix.fonts.monospace.name;
            baseFontSize = 16;
          };
          cssSnippets = [
            {
              name = "stylix";
              text = stylixCss;
            }
          ];
          # Install is declarative; per-plugin settings stay writable in-app
          # (no `settings`, so each plugin owns its own data.json).
          communityPlugins = plugins;
        };
      };
      vaults.projects = {
        target = "workspace/github.com/tonybutt/projects";
        settings = {
          appearance = {
            theme = "obsidian";
            interfaceFontFamily = config.stylix.fonts.sansSerif.name;
            textFontFamily = config.stylix.fonts.sansSerif.name;
            monospaceFontFamily = config.stylix.fonts.monospace.name;
            baseFontSize = 16;
          };
          cssSnippets = [
            {
              name = "stylix";
              text = stylixCss;
            }
          ];
          communityPlugins = projectsPlugins;
        };
      };
    };
  };
}
