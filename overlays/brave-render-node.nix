# Chromium's Ozone/Wayland backend picks its GPU render node from the
# compositor's device and injects --render-node-override into its own GPU
# process before Mesa is ever initialised. On atlas that is the Phoenix1 iGPU,
# because Hyprland owns the displays — so DRI_PRIME and MESA_VK_DEVICE_SELECT
# are structurally unable to move Brave to the Navi 33. (Confirmed: launching
# with --ozone-platform=x11 emits no override at all, and both render nodes
# expose identical VA-API, so this is not the VA-API node finder choosing.)
#
# Re-derive the override from DRI_PRIME so Brave simply follows whatever GPU
# the rest of the session was pointed at — including the on-the-go
# specialisation, which hands rendering back to the iGPU on battery. Addressed
# through /dev/dri/by-path so the choice survives renderD* renumbering across
# boots, matching how DRI_PRIME itself is set.
#
# DRI_PRIME spells the address pci-<domain>_<bus>_<dev>_<func>; by-path spells
# the same device pci-<domain>:<bus>:<dev>.<func>. Note the final separator is a
# dot, not a colon — a blanket _ -> : swap yields a path that never resolves.
final: prev: {
  brave = prev.brave.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/brave \
        --run ${final.lib.escapeShellArg ''
          if [[ ''${DRI_PRIME:-} =~ ^pci-([0-9a-fA-F]+)_([0-9a-fA-F]+)_([0-9a-fA-F]+)_([0-9a-fA-F]+)$ ]]; then
            _braveNode="/dev/dri/by-path/pci-''${BASH_REMATCH[1]}:''${BASH_REMATCH[2]}:''${BASH_REMATCH[3]}.''${BASH_REMATCH[4]}-render"
            [[ -e $_braveNode ]] && export BRAVE_RENDER_NODE=$_braveNode
            unset _braveNode
          fi
        ''} \
        --add-flags ${final.lib.escapeShellArg "\${BRAVE_RENDER_NODE:+--render-node-override=$BRAVE_RENDER_NODE}"}

      # The flag is only useful if it reaches the exec line unquoted, so that it
      # expands at launch rather than being passed through as a literal.
      grep -q 'BRAVE_RENDER_NODE:+--render-node-override=' $out/bin/brave || {
        echo "render-node-override flag did not reach the brave wrapper" >&2
        exit 1
      }
    '';
  });
}
