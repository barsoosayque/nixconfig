{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScript;
  inherit (config.helpers) mkAllEventsCallback;

  cfg = config.modules.services.dunst;

  notifyScript = writeScript "dunst-notify-script" ''
    #!${pkgs.dash}/bin/dash
    ${pkgs.libnotify}/bin/notify-send "System event completed" "$EVENT_DESCRIPTION"
  '';
in
{
  options.modules.services.dunst = {
    enable = mkEnableOption "dunst";
    notifySystemEvents = mkEnableOption "notify system events using dunst";
  };

  config = mkIf cfg.enable {
    homeManager.services.dunst = {
      enable = true;
    };

    system.events = mkIf cfg.notifySystemEvents (mkAllEventsCallback "afterCommands" notifyScript);
  };
}
