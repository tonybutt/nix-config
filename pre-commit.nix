{
  pkgs,
  pre-commit-hooks,
  treefmtEval,
}:
let
  inherit (pkgs) lib;

  waybar-unstable-check = pkgs.writeShellApplication {
    name = "waybar-unstable-check";
    runtimeInputs = [
      pkgs.curl
      pkgs.gnugrep
      pkgs.gnused
      pkgs.coreutils
    ];
    text = ''
      wanted=0.16.0
      url=https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/pkgs/by-name/wa/waybar/package.nix
      if ! expr=$(curl -fsSL --max-time 10 "$url"); then
        echo "waybar-unstable-check: GitHub unreachable, skipping" >&2
        exit 0
      fi
      current=$(grep -m1 -E '^  version = "[0-9.]+";' <<<"$expr" | sed -E 's/.*"(.*)".*/\1/')
      if [ -z "$current" ]; then
        echo "waybar-unstable-check: could not read waybar version from nixos-unstable" >&2
        exit 1
      fi
      newest=$(printf '%s\n%s\n' "$wanted" "$current" | sort -V | tail -n1)
      if [ "$newest" = "$current" ]; then
        echo "nixos-unstable now ships waybar $current (>= $wanted)." >&2
        echo "Run nix flake update nixpkgs, then drop overlays/waybar-nixpkgs-master.nix, the nixpkgs-master input and this hook." >&2
        exit 1
      fi
    '';
  };
in
pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
  src = ./.;
  hooks = {
    flake-checker = {
      enable = true;
      package = pkgs.flake-checker;
    };
    treefmt-nix = {
      enable = true;
      entry = "${treefmtEval.config.build.wrapper}/bin/treefmt --ci";
      pass_filenames = false;
    };
    convco = {
      enable = true;
      package = pkgs.convco;
    };
    waybar-unstable = {
      enable = true;
      name = "waybar-unstable";
      entry = lib.getExe waybar-unstable-check;
      pass_filenames = false;
      always_run = true;
    };
  };
}
