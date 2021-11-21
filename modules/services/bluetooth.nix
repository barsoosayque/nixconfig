{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.services.bluetooth;
in
{
  options.modules.services.bluetooth = {
    enable = mkEnableOption "bluetooth";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings = {
      General.Enable = "Source,Sink,Media,Socket";
    };
    services.blueman.enable = true;
  };
}
