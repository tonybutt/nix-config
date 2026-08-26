{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.terminals;
  inherit (lib) mkIf mkEnableOption;

  # Handles ghostty://open?path=<url-encoded dir>, so notes and dashboards
  # (the projects vault's Home.md) can link a checkout that opens a
  # terminal there. Only ever sets a working directory — the URI cannot
  # carry a command to run.
  ghostty-open = pkgs.writeShellScriptBin "ghostty-open" ''
    uri="''${1:-}"
    query="''${uri#ghostty://open}"
    query="''${query#\?}"

    dir=""
    IFS='&' read -ra params <<< "$query"
    for param in "''${params[@]}"; do
      case "$param" in
        path=*)
          encoded="''${param#path=}"
          encoded="''${encoded//+/ }"
          dir="$(printf '%b' "''${encoded//%/\\x}")"
          ;;
      esac
    done

    if [ -z "$dir" ]; then
      echo "no path in URI: $uri" >&2
      exit 1
    fi

    case "$dir" in
      "~/"*) dir="$HOME/''${dir#\~/}" ;;
    esac

    if [ ! -d "$dir" ]; then
      echo "not a directory: $dir" >&2
      exit 1
    fi

    exec ${lib.getExe config.programs.ghostty.package} --working-directory="$dir"
  '';
in
{
  options = {
    modules.terminals.ghostty.enable = mkEnableOption "Enable Ghostty terminal" // {
      default = false;
    };
  };
  config = mkIf cfg.ghostty.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        gtk-single-instance = true;
        copy-on-select = "clipboard";
        clipboard-trim-trailing-spaces = true;
        font-size = 14;
        window-decoration = false;
        background-opacity = 0.8;
      };
    };

    xdg.desktopEntries.ghostty-open = {
      name = "Ghostty (open directory)";
      comment = "Open a terminal at the directory named by a ghostty:// URI";
      exec = "${lib.getExe ghostty-open} %u";
      icon = "com.mitchellh.ghostty";
      terminal = false;
      noDisplay = true;
      mimeType = [ "x-scheme-handler/ghostty" ];
      categories = [
        "System"
        "TerminalEmulator"
      ];
    };

    xdg.mimeApps.defaultApplications."x-scheme-handler/ghostty" = [ "ghostty-open.desktop" ];
  };
}
