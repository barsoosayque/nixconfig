{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScript;
  inherit (config.helpers) mkAllEventsCallback;

  cfg = config.modules.services.dunst;

  notifySend = "${pkgs.libnotify}/bin/notify-send";

  mkSendScript = { title, msg, icon ? null, ... }: writeScript "dunst-event-script" ''
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
        ${notifySend} "$TITLE" "$MSG" \
        ${strings.optionalString (icon != null) "--icon=${icon}" }
  '';

  scripts = {
    default = mkSendScript { 
      title = "$EVENT_DESCRIPTION";
      msg = "Completed";
      icon = pkgsLocal.remixicon.mkIcon { id = "notification-line"; };
    };

    screenshoot = mkSendScript {
      title = "$EVENT_DESCRIPTION";
      msg = "Saved to clipboard and $SCREENSHOT_PATH";
      icon = pkgsLocal.remixicon.mkIcon { id = "screenshot-line"; };
    };
  };
in
{
  options.modules.services.dunst = {
    enable = mkEnableOption "dunst";
    notifySystemEvents = mkEnableOption "notify system events using dunst";

    font = {
      package = mkOption {
        type = types.package;
        default = pkgs.ubuntu_font_family;
        description = "Font nix package";
      };

      name = mkOption {
        type = types.str;
        default = "Ubuntu";
        description = "Font name according to the package";
      };

      size = mkOption {
        type = types.int;
        default = 11;
        description = "Text size";
      };
    };
  };

  config = mkIf cfg.enable {
    fonts.fonts = [ cfg.font.package ];

    homeManager.services.dunst = {
      enable = true;

      settings = {
        global = {
          offset = "12x12";
          transparency = 25;
          padding = 10;
          horizontal_padding = 10;
          frame_width = 1;
          font = "${cfg.font.name} ${toString cfg.font.size}";
        };
      };
    };

    system.events = mkIf cfg.notifySystemEvents {
      onReloadCallbacks.afterCommands = [ scripts.default ];
      onTorrentDoneCallbacks.afterCommands = [ scripts.default ];
      onScreenshotCallbacks.afterCommands = [ scripts.screenshoot ];
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
