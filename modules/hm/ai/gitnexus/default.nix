{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.ai.gitnexus;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  options.modules.ai.gitnexus = {
    enable = mkEnableOption "Enable GitNexus - code knowledge graph creator with MCP integration";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "The gitnexus package to install";
    };

    analyzeExtraFlags = mkOption {
      type = types.listOf types.str;
      default = [ "--skip-agents-md" ];
      description = ''
        Flags appended to every `gitnexus analyze` invocation. The default
        keeps analyze from regenerating the gitnexus section in CLAUDE.md /
        AGENTS.md, which would clobber local customizations of that block
        (and churn the volatile symbol counts).
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      # Wrapper first so it wins the bin/gitnexus conflict in symlinkJoin;
      # non-analyze subcommands (mcp, query, ...) pass through untouched
      (pkgs.symlinkJoin {
        name = "gitnexus";
        paths = [
          (pkgs.writeShellScriptBin "gitnexus" ''
            if [ "''${1:-}" = "analyze" ]; then
              exec ${cfg.package}/bin/gitnexus "$@" ${lib.escapeShellArgs cfg.analyzeExtraFlags}
            fi
            exec ${cfg.package}/bin/gitnexus "$@"
          '')
          cfg.package
        ];
      })
    ];
  };
}
