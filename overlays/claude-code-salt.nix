{ salt }:
_final: prev: {
  claude-code = prev.claude-code.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      for bin in $out/bin/.claude-unwrapped $out/bin/claude; do
        if [ -f "$bin" ] && grep -q "friend-2026-401" "$bin"; then
          ${prev.perl}/bin/perl -pi -e 's/friend-2026-401/${salt}/g' "$bin"
        fi
      done
    '';
  });
}
