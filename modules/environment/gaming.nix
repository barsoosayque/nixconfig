{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.modules.environment.gaming;
in
{
  options.modules.environment.gaming = {
    enable = mkEnableOption "gaming environment";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.logmein-hamachi
      pkgs.lutris
      pkgs.steam
    ];
    
    programs.steam.enable = true;
  };
}
