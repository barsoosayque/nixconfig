{ config, pkgs, pkgsLocal, lib, ... }:

let
  inherit (lib) mkOption types;
  inherit (builtins) attrNames;

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
      type = with types; enum (attrNames locations);
      description = "Location name of host";
    };

    location = mkOption {
      type = with types; attrs;
      readOnly = true;
      description = "Read-only parameters of host location";
    };
  };

  config =
    let
      location = locations."${cfg.locationName}";
    in
    {
      system.locale.location = location;
      time.timeZone = location.timeZone;
    };
}
