{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.modules.services.thinkfan;

  systemctl = "${pkgs.systemd}/bin/systemctl";
  sudo = "/run/wrappers/bin/sudo";

  notifyEnabled = config.modules.services.dunst.notify {
    title = "Thinkfan";
    msg = "Enabled";
    icon = "typhoon-fill";
  };

  notifyDisabled = config.modules.services.dunst.notify {
    title = "Thinkfan";
    msg = "Disabled";
    icon = "typhoon-line";
  };

  toggleScript = pkgs.writeShellScript "thinkfan-toggle" ''
    if ${systemctl} is-active --quiet thinkfan; then
      ${sudo} ${systemctl} stop thinkfan
      ${notifyDisabled}
    else
      ${sudo} ${systemctl} start thinkfan
      ${notifyEnabled}
    fi
  '';
in
{
  options.modules.services.thinkfan = {
    enable = mkEnableOption "thinkfan";

    sensors = mkOption {
      type = with types; listOf attrs;
      default = [
        {
          query = "/proc/acpi/ibm/thermal";
          type = "tpacpi";
        }
      ];
      description = "thinkfan sensors, see services.thinkfan.sensors";
    };

    fans = mkOption {
      type = with types; listOf attrs;
      default = [
        {
          type = "tpacpi";
          query = "/proc/acpi/ibm/fan";
        }
      ];
      description = "thinkfan fans, see services.thinkfan.fans";
    };

    levels = mkOption {
      type = with types; listOf (listOf int);
      default = [
        [ 0 0 45 ]
        [ 1 43 50 ]
        [ 2 48 55 ]
        [ 3 53 60 ]
        [ 4 58 65 ]
        [ 5 63 70 ]
        [ 7 68 80 ]
        [ 127 75 32767 ]
      ];
      description = "thinkfan levels, see services.thinkfan.levels";
    };
  };

  config = mkIf cfg.enable {
    services.thinkfan = {
      enable = true;
      inherit (cfg) sensors fans levels;
    };

    system.keyboard.bindings = {
      "super + shift + o" = toggleScript;
    };
  };
}
