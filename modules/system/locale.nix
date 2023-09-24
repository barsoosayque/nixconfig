{ config, pkgs, lib, ... }:

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
    Podgorica = {
      latitude = 42.4399123;
      longitude = 19.2627733;
      timeZone = "Europe/Podgorica";
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
