{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.services.picom;
in
{
  options.modules.services.picom = {
    enable = mkEnableOption "picom";
  };

  config = mkIf cfg.enable {
    system.user.hm.services.picom = {
      enable = true;
      blur = true;
      shadow = true;
    };
  };
}
