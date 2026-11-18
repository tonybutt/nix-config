{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.ai.security-audit;
  inherit (lib)
    mkIf
    mkEnableOption
    ;
in
{
  options.modules.ai.security-audit = {
    enable = mkEnableOption "Cloudflare's security-audit Claude skill";
  };

  config = mkIf cfg.enable {
    # Binaries the skill relies on: node runs the findings and
    # coverage-ledger validators; bubblewrap, nsjail, util-linux (unshare,
    # prlimit) and coreutils (env -i, timeout) provide the OS-enforced
    # sandbox it requires before executing target code.
    home.packages = with pkgs; [
      nodejs
      bubblewrap
      nsjail
      util-linux
      coreutils
      ripgrep
      jq
    ];

    # Use cp -rL activation instead of home.file symlinks because
    # Claude Code's skill discovery does not follow symlinks.
    home.activation.security-audit-skill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/.claude/skills
      rm -rf $HOME/.claude/skills/security-audit
      cp -rL ${inputs.security-audit-skill}/skills/security-audit $HOME/.claude/skills/
      chmod -R u+rw $HOME/.claude/skills/security-audit
    '';
  };
}
