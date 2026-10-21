{
  pkgs,
  inputs,
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
      default = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.gitnexus;
      description = "The gitnexus package to install";
    };

    analyzeExtraFlags = mkOption {
      type = types.listOf types.str;
      default = [ "--no-stats" ];
      description = ''
        Flags appended to every `gitnexus analyze` invocation. The default
        drops the volatile symbol counts from the gitnexus section in
        CLAUDE.md / AGENTS.md so analyze doesn't churn them. Pair it with a
        `<!-- gitnexus:keep -->` marker inside that block to stop analyze
        from replacing a customized block with the stock template.
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
              exec ${lib.getExe cfg.package} "$@" ${lib.escapeShellArgs cfg.analyzeExtraFlags}
            fi
            exec ${lib.getExe cfg.package} "$@"
          '')
          cfg.package
        ];
      })
    ];
  };
}
