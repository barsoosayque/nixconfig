{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.programs.virtualbox;
in
{
  options.modules.programs.virtualbox = {
    enable = mkEnableOption "virtualbox";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.virtualbox ];
    virtualisation.virtualbox.host.enable = true;
    users.extraGroups.vboxusers.members = [ config.system.user.name ];
  };
}
