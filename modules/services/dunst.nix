{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScript;
  inherit (config.helpers) mkAllEventsCallback;

  cfg = config.modules.services.dunst;

  notifySend = "${pkgs.libnotify}/bin/notify-send";

  mkSendScript = title: msg: writeScript "dunst-event-script" ''
    #!${pkgs.dash}/bin/dash

    # see https://github.com/phuhl/notify-send.py#notify-sendpy-as-root-user
    # and https://dunst-project.org/faq/

    export XAUTHORITY=${config.userDirs.home}/.Xauthority
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString config.currentUser.uid}/bus

    TITLE="${title}"
    MSG="${msg}"

    /run/wrappers/bin/sudo -u ${config.currentUser.name} \
        XAUTHORITY=${config.userDirs.home}/.Xauthority \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString config.currentUser.uid}/bus \
        ${notifySend} "$TITLE" "$MSG"
  '';

  defaultNotifyScript = mkSendScript "$EVENT_DESCRIPTION" "Completed";

  screenshotMadeScrtipt = mkSendScript "$EVENT_DESCRIPTION" "Saved to clipboard and $SCREENSHOT_PATH";
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

    system.events = mkIf cfg.notifySystemEvents {
      onReloadCallbacks.afterCommands = [ defaultNotifyScript ];
      onTorrentDoneCallbacks.afterCommands = [ defaultNotifyScript ];
      onScreenshotCallbacks.afterCommands = [ screenshotMadeScrtipt ];
    };

    # whitelist notify-send so other users can run onEventScript and trigger notifications
    security.sudo.extraRules = [
      { 
        users = [ "ALL" ]; 
        runAs = config.currentUser.name; 
        commands = [ { command = notifySend; options = [ "NOPASSWD" "SETENV" ]; } ];
      }
    ];
  };
}
