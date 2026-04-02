{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.sops;
in
{
  options = {
    modules.sops.enable = mkEnableOption "Enable sops-nix secret management";
  };
  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      secrets = {
        github-runner-token = { };
      };
    };
  };
}
