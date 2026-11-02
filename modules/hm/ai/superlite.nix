{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.ai.superlite;
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  plugin = inputs.superlite.packages.${pkgs.stdenv.hostPlatform.system}.plugin;
  sl = pkgs.runCommand "superlite-sl" { meta.mainProgram = "sl"; } ''
    mkdir -p $out/bin
    ln -s ${plugin}/bin/sl $out/bin/sl
  '';
in
{
  options.modules.ai.superlite = {
    enable = mkEnableOption "Enable the superlite plugin for Claude Code";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.modules.ai.superpowers.enable;
        message = "modules.ai.superlite and modules.ai.superpowers share skill names; set modules.ai.superpowers.enable = false.";
      }
    ];

    home = {
      packages = [ sl ];
      file.".claude/plugins/superlite".source = plugin;
    };

    modules.ai.claude-settings = {
      enabledPlugins."superlite@superlite-dev" = true;
      extraKnownMarketplaces.superlite-dev.source = {
        source = "directory";
        path = "${config.home.homeDirectory}/.claude/plugins/superlite";
      };
    };
  };
}
