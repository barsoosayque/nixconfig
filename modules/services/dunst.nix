{
  config,
  pkgs,
  pkgsRepo,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    mkEnableOption
    types
    ;
  inherit (lib.strings) optionalString;
  inherit (pkgs) writeScript;

  cfg = config.modules.services.dunst;

  notifySend = "${pkgs.libnotify}/bin/notify-send";

  # Scripts built via `notify` may run as an arbitrary other user (root doing a
  # system-level event, or a sandboxed service like transmission-daemon that
  # blocks setuid entirely via seccomp) and can't reach the interactive user's
  # D-Bus session/X display directly, nor become that user via sudo. Instead
  # they drop an event into this directory - world-writable and normally
  # reachable even from inside a service sandbox, since /run is almost always
  # bind-mounted in - and a relay service running natively as the interactive
  # user (below) picks it up and fires the real notification.
  notifyQueueDir = "/run/dunst-notify-queue";

  mkIcon =
    id:
    pkgsRepo.local.remixicon.mkIcon {
      inherit id;
      color = config.system.pretty.theme.colors.notification.accent;
    };

  mkSendScript =
    {
      title,
      msg,
      icon ? null,
      ...
    }:
    let
      iconPath = if icon == null then null else mkIcon icon;
    in
    writeScript "dunst-event-script" ''
      #!${pkgs.dash}/bin/dash

      TITLE="${title}"
      MSG="${msg}"

      EVENT_ID="$$-$(date +%s%N)"
      printf '%s' "$TITLE" > "${notifyQueueDir}/$EVENT_ID.title"
      printf '%s' "$MSG" > "${notifyQueueDir}/$EVENT_ID.msg"
      ${optionalString (iconPath != null) ''printf '%s' "${iconPath}" > "${notifyQueueDir}/$EVENT_ID.icon"''}
      : > "${notifyQueueDir}/$EVENT_ID.ready"
    '';

  notifyRelayScript = pkgs.writeShellScript "dunst-notify-relay" ''
    export XAUTHORITY=${config.system.user.home}/.Xauthority
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString config.system.user.uid}/bus

    ${pkgs.inotify-tools}/bin/inotifywait -m -e close_write -e moved_to --format '%f' "${notifyQueueDir}" |
    while IFS= read -r name; do
      case "$name" in
        *.ready)
          id="''${name%.ready}"
          TITLE=$(cat "${notifyQueueDir}/$id.title" 2>/dev/null)
          MSG=$(cat "${notifyQueueDir}/$id.msg" 2>/dev/null)
          if [ -f "${notifyQueueDir}/$id.icon" ]; then
            ICON=$(cat "${notifyQueueDir}/$id.icon")
            ${notifySend} "$TITLE" "$MSG" --icon="$ICON"
          else
            ${notifySend} "$TITLE" "$MSG"
          fi
          rm -f "${notifyQueueDir}/$id.title" "${notifyQueueDir}/$id.msg" "${notifyQueueDir}/$id.icon" "${notifyQueueDir}/$id.ready"
          ;;
      esac
    done
  '';

  scripts = {
    default = mkSendScript {
      title = "$EVENT_DESCRIPTION";
      msg = "Completed";
      icon = "notification-line";
    };

    screenshoot = mkSendScript {
      title = "$EVENT_DESCRIPTION";
      msg = "Saved to clipboard and $SCREENSHOT_PATH";
      icon = "screenshot-line";
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
        default = pkgs.ubuntu-classic;
        description = "Font nix package";
      };

      name = mkOption {
        type = with types; str;
        default = "Ubuntu Medium";
        description = "Font name according to the package";
      };

      size = mkOption {
        type = with types; int;
        default = 12;
        description = "Text size";
      };
    };

    notify = mkOption {
      type = with types; functionTo package;
      readOnly = true;
      description = ''
        Function `{ title, msg, icon ? null }: <script>` other modules can use
        to send a notification through dunst instead of calling notify-send directly.
        `icon`, if given, is a RemixIcon id (e.g. "screenshot-line").
      '';
    };
  };

  config = mkMerge [
    { modules.services.dunst.notify = mkSendScript; }

    (mkIf cfg.enable {
      fonts.packages = [ cfg.font.package ];

      systemd.tmpfiles.rules = [ "d ${notifyQueueDir} 1777 root root -" ];

      system.user.hm = {
        services.dunst = {
          enable = true;

          settings = {
            global = {
              follow = "keyboard";

              offset = "20x20";
              padding = 20;
              horizontal_padding = 20;
              width = 400;
              height = 200;

              frame_width = 1;
              separator_width = 1;
              corner_radius = 2;

              frame_color = config.system.pretty.theme.colors.notification.foreground.hexRGBA;
              background = config.system.pretty.theme.colors.notification.background.hexRGBA;
              foreground = config.system.pretty.theme.colors.notification.foreground.hexRGBA;

              font = "${cfg.font.name} ${toString cfg.font.size}";
            };
          };
        };

        systemd.user.services.dunst-notify-relay = {
          Unit.Description = "Relay queued dunst notifications from sandboxed/other-user producers";
          Install.WantedBy = [ "default.target" ];
          Service = {
            Type = "simple";
            ExecStart = "${notifyRelayScript}";
            Restart = "always";
          };
        };
      };

      system.events = mkIf cfg.notifySystemEvents {
        onReloadCallbacks.afterCommands = [ scripts.default ];
        onScreenshotCallbacks.afterCommands = [ scripts.screenshoot ];
      };
    })
  ];
}
