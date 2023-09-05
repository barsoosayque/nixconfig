{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.grocy;
in
{
  options.modules.services.grocy = {
    enable = mkEnableOption "grocy";
  };

  config = mkIf cfg.enable {
    services.grocy = {
      enable = true;
      hostName = "grocy";
      nginx.enableSSL = false;
      settings = {
        currency = "RUB";
        culture = "ru";
        calendar.firstDayOfWeek = 1;
      };
    };

    services.nginx.virtualHosts."grocy".listen = [{
      port = 9093;      
      addr = "192.168.0.111";
    }];
  };
}
