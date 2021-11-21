{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.services.redshift;
  locations = {
    Abakan = {
      latitude = 53.716667;
      longitude = 91.46667;
    };
  };
in
{
  options.modules.services.redshift = {
    enable = mkEnableOption "redshift";

    location = mkOption {
      type = types.enum (attrNames locations);
      description = "Location of host";
    };
  };

  config = mkIf cfg.enable {
    homeManager.services.redshift = {
      enable = true;
      provider = "manual";
      latitude = locations."${cfg.location}".latitude;
      longitude = locations."${cfg.location}".longitude;
    };
  };
}
