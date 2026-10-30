{
  pkgs,
  pre-commit-hooks,
  treefmtEval,
}:
let
  inherit (pkgs) lib;

  waybar-release-check = pkgs.writeShellApplication {
    name = "waybar-release-check";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      known=0.15.0
      if ! release=$(curl -fsSL --max-time 10 https://api.github.com/repos/Alexays/Waybar/releases/latest); then
        echo "waybar-release-check: GitHub unreachable, skipping" >&2
        exit 0
      fi
      tag=$(jq -r .tag_name <<<"$release")
      latest=''${tag#v}
      newest=$(printf '%s\n%s\n' "$known" "$latest" | sort -V | tail -n1)
      if [ "$newest" != "$known" ]; then
        echo "Waybar $latest is out (newer than $known)." >&2
        echo "If it carries the Alexays/Waybar#5316 fix, drop overlays/waybar-hyprland-ipc.nix and this hook." >&2
        exit 1
      fi
    '';
  };
in
pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
  src = ./.;
  hooks = {
    flake-checker.enable = true;
    treefmt-nix = {
      enable = true;
      entry = "${treefmtEval.config.build.wrapper}/bin/treefmt --ci";
      pass_filenames = false;
    };
    convco.enable = true;
    waybar-release = {
      enable = true;
      name = "waybar-release";
      entry = lib.getExe waybar-release-check;
      pass_filenames = false;
      always_run = true;
    };
  };
}
