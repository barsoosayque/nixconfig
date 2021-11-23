{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.system.locale;

  locations = {
    Abakan = {
      latitude = 53.716667;
      longitude = 91.46667;
      timeZone = "Asia/Krasnoyarsk";
    };
  };
in
{
  options.system.locale = {
    locationName = mkOption {
      type = types.enum (attrNames locations);
      description = "Location name of host";
    };

    location = mkOption {
      type = types.attrs;
      readOnly = true;
      description = "Read-only parameters of host location";
    };
  };

  config = let
    location = locations."${cfg.locationName}";
  in {
    system.locale.location = location;
    time.timeZone = location.timeZone;
  };
}
