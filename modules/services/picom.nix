{ config, options, pkgs, pkgsLocal, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

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
