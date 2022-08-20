{ config, options, pkgs, pkgsRepo, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (lib.strings) optionalString;
  inherit (pkgs) writeScript;
  inherit (config.helpers) mkAllEventsCallback;

  cfg = config.modules.services.dunst;

  notifySend = "${pkgs.libnotify}/bin/notify-send";

  mkSendScript = { title, msg, icon ? null, ... }: writeScript "dunst-event-script" ''
    #!${pkgs.dash}/bin/dash

    # see https://github.com/phuhl/notify-send.py#notify-sendpy-as-root-user
    # and https://dunst-project.org/faq/

    export XAUTHORITY=${config.system.user.home}/.Xauthority
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString config.system.user.uid}/bus

    TITLE="${title}"
    MSG="${msg}"

    /run/wrappers/bin/sudo -u ${config.system.user.name} \
        XAUTHORITY=${config.system.user.home}/.Xauthority \
        DISPLAY=:0 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString config.system.user.uid}/bus \
        ${notifySend} "$TITLE" "$MSG" \
        ${optionalString (icon != null) "--icon=${icon}" }
  '';

  scripts = {
    default = mkSendScript {
      title = "$EVENT_DESCRIPTION";
      msg = "Completed";
      icon = pkgsRepo.local.remixicon.mkIcon { id = "notification-line"; color = config.system.pretty.theme.colors.notification.accent; };
    };

    torrent = mkSendScript {
      title = "$EVENT_DESCRIPTION";
      msg = "$TR_TORRENT_NAME";
      icon = pkgsRepo.local.remixicon.mkIcon { id = "folder-download-line"; color = config.system.pretty.theme.colors.notification.accent; };
    };

    screenshoot = mkSendScript {
      title = "$EVENT_DESCRIPTION";
      msg = "Saved to clipboard and $SCREENSHOT_PATH";
      icon = pkgsRepo.local.remixicon.mkIcon { id = "screenshot-line"; color = config.system.pretty.theme.colors.notification.accent; };
    };
  };
in
{
  options.modules.services.dunst = {
    enable = mkEnableOption "dunst";
    notifySystemEvents = mkEnableOption "notify system events using dunst";

    font = {
      package = mkOption {
        type = with types; package;
        default = pkgs.ubuntu_font_family;
        description = "Font nix package";
      };

      name = mkOption {
        type = with types; str;
        default = "Ubuntu";
        description = "Font name according to the package";
      };

      size = mkOption {
        type = with types; int;
        default = 11;
        description = "Text size";
      };
    };
  };

  config = mkIf cfg.enable {
    fonts.fonts = [ cfg.font.package ];

    system.user.hm.services.dunst = {
      enable = true;

      settings = {
        global = {
          offset = "20x20";
          padding = 20;
          horizontal_padding = 20;
          width = 400;
          height = 200;

          frame_width = 1;
          frame_color = config.system.pretty.theme.colors.notification.foreground.hexRGBA;
          background = config.system.pretty.theme.colors.notification.background.hexRGBA;
          foreground = config.system.pretty.theme.colors.notification.foreground.hexRGBA;
          font = "${cfg.font.name} ${toString cfg.font.size}";
        };
      };
    };

    system.events = mkIf cfg.notifySystemEvents {
      onReloadCallbacks.afterCommands = [ scripts.default ];
      onTorrentDoneCallbacks.afterCommands = [ scripts.torrent ];
      onScreenshotCallbacks.afterCommands = [ scripts.screenshoot ];
    };

    # whitelist notify-send so other users can run onEventScript and trigger notifications
    security.sudo.extraRules = [
      {
        users = [ "ALL" ];
        runAs = config.system.user.name;
        commands = [{ command = notifySend; options = [ "NOPASSWD" "SETENV" ]; }];
      }
    ];
  };
}
