{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.ssh;
in
{
  options = {
    modules.ssh.enable = mkEnableOption "Enable SSH client configuration" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        mantra = {
          hostname = "mantra.lan";
          user = "anthony";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/id_ed25519_sk" ];
        };
        lapnix = {
          hostname = "lapnix.lan";
          user = "anthony";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/id_ed25519_sk" ];
        };
        atlas = {
          hostname = "atlas.lan";
          user = "anthony";
          identitiesOnly = true;
          identityFile = [ "~/.ssh/id_ed25519_sk" ];
        };
      };
    };
  };
}
