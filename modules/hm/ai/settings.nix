{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.ai.claude-settings;
  inherit (lib)
    mkOption
    types
    ;
in
{
  options.modules.ai.claude-settings = mkOption {
    type = types.attrsOf types.anything;
    default = { };
    description = "Nix-managed keys to deep-merge into ~/.claude/settings.json";
  };

  config = lib.mkIf (cfg != { }) {
    home.activation.claude-settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SETTINGS="$HOME/.claude/settings.json"
      NIX_SETTINGS='${builtins.toJSON cfg}'
      if [ -f "$SETTINGS" ]; then
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$SETTINGS" <(echo "$NIX_SETTINGS") > "$SETTINGS.tmp"
        mv "$SETTINGS.tmp" "$SETTINGS"
      else
        mkdir -p "$(dirname "$SETTINGS")"
        echo "$NIX_SETTINGS" | ${pkgs.jq}/bin/jq '.' > "$SETTINGS"
      fi
    '';
  };
}
