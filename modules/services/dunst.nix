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
          ${optionalString (iconPath != null) "--icon=${iconPath}"}
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

      system.user.hm.services.dunst = {
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

      system.events = mkIf cfg.notifySystemEvents {
        onReloadCallbacks.afterCommands = [ scripts.default ];
        onScreenshotCallbacks.afterCommands = [ scripts.screenshoot ];
      };

      # whitelist notify-send so other users can run onEventScript and trigger notifications
      security.sudo.extraRules = [
        {
          users = [ "ALL" ];
          runAs = config.system.user.name;
          commands = [
            {
              command = notifySend;
              options = [
                "NOPASSWD"
                "SETENV"
              ];
            }
          ];
        }
      ];
    })
  ];
}
