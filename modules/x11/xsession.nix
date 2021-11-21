{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.x11.xsession;
in
{
  options.modules.x11.xsession = {
    enable = mkEnableOption "xsession";
  };

  config = mkIf cfg.enable {
    homeManager.xsession = {
      enable = true;

      # we are using startx, so our xsession should be just xinitrc
      scriptPath = ".xinitrc";
    };
  };
}
