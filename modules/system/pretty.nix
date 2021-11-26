{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScriptBin;

  cfg = config.system.pretty;

  setrootBin = "${pkgs.setroot}/bin/setroot";
in
{
  options.system.pretty = {
    backgroundEnable = mkEnableOption "background management";
  };

  config = {
    system.events.onStartup = lists.optional cfg.backgroundEnable
      "${setrootBin} --restore";
    
    environment.systemPackages = lists.optional cfg.backgroundEnable
      (writeScriptBin "background" "${setrootBin} --store $@");
  };
}
