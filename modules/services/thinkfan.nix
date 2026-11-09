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
      # [ level lower upper ]: step up when temp > upper, back down when < lower.
      # Alder Lake H sits at 80-90°C under sustained load, so ramp gently and
      # only go "disengaged" (127, beyond full speed) when actually near tjmax.
      # Gaps of ~5°C between lower/upper keep short CPU spikes from flapping it.
      default = [
        [ 0 0 55 ]
        [ 1 50 62 ]
        [ 2 57 68 ]
        [ 3 63 73 ]
        [ 4 68 78 ]
        [ 5 73 83 ]
        [ 6 78 87 ]
        [ 7 82 93 ]
        [ 127 89 32767 ]
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
