{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.services.redshift;
in
{
  options.modules.services.redshift = {
    enable = mkEnableOption "redshift";
  };

  config = mkIf cfg.enable {
    system.user.hm.services.redshift = {
      enable = true;
      provider = "manual";
      latitude = config.system.locale.location.latitude;
      longitude = config.system.locale.location.longitude;
    };
  };
}
