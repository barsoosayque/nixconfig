{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.services.sxhkd;
in
{
  options.modules.services.sxhkd = {
    enable = mkEnableOption "sxhkd";
  };

  config = mkIf cfg.enable {
    events.onReload = [ "pkill -USR1 -x sxhkd" ];
    
    modules.keyboard.bindings = {
      "super + shift + r" = "${config.events.onReloadCmd}";
    };

    homeManager.services.sxhkd = {
      enable = true;
      keybindings = mkAliasDefinitions options.modules.keyboard.bindings;
    };
  };
}
