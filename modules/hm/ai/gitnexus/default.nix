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
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
