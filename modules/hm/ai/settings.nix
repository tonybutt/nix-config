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
        # jq's `*` replaces arrays wholesale, which would wipe entries Claude
        # adds at runtime (e.g. "always allow" MCP permissions); union them
        ${lib.getExe pkgs.jq} -s '
          def merge($a; $b):
            if ($a | type) == "object" and ($b | type) == "object" then
              reduce ($b | keys_unsorted[]) as $k ($a; .[$k] = merge($a[$k]; $b[$k]))
            elif ($a | type) == "array" and ($b | type) == "array" then
              $a + ($b - $a)
            else $b end;
          merge(.[0]; .[1])
        ' "$SETTINGS" <(echo "$NIX_SETTINGS") > "$SETTINGS.tmp"
        mv "$SETTINGS.tmp" "$SETTINGS"
      else
        mkdir -p "$(dirname "$SETTINGS")"
        echo "$NIX_SETTINGS" | ${lib.getExe pkgs.jq} '.' > "$SETTINGS"
      fi
    '';
  };
}
