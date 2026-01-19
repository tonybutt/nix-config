{
  pkgs,
  config,
  lib,
  user,
  ...
}:
with lib;
let
  cfg = config.modules;
in
{
  options = {
    modules.users.enable = mkEnableOption "Enable users module" // {
      default = true;
    };
  };
  config = mkIf cfg.users.enable {
    users = {
      defaultUserShell = pkgs.zsh;
      users.${user.username} = {
        isNormalUser = true;
        home = "/home/${user.username}";
        extraGroups = [
          "wheel"
          "networkmanager"
          "input"
        ];
      };
    };
  };
}
