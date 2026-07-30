{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    ;
  inherit (lib.strings) concatMapStringsSep;
  inherit (lib.attrsets) listToAttrs;

  cfg = config.modules.services.battery;

  # State file tracks the lowest threshold already notified for the current
  # discharge cycle, so a "change" uevent that fires repeatedly around the
  # same capacity (or on tiny voltage/current fluctuations) doesn't re-notify.
  # Lives in /run so it naturally resets on reboot; also reset whenever we're
  # not discharging (charging/full/unknown), so the next discharge re-arms it.
  lowBatteryStateFile = "/run/battery-notify-last-threshold";

  sortedThresholds = lib.sort builtins.lessThan cfg.lowBatteryThresholds;

  notifyCharging = config.modules.services.dunst.notify {
    title = "Battery";
    msg = "Charging";
    icon = "battery-charge-line";
  };

  notifyOnBattery = config.modules.services.dunst.notify {
    title = "Battery";
    msg = "On battery";
    icon = "battery-line";
  };

  lowBatteryNotifyScripts = listToAttrs (
    map (threshold: {
      name = toString threshold;
      value = config.modules.services.dunst.notify {
        title = "Battery";
        msg = "Battery at ${toString threshold}%";
        icon = "battery-low-line";
      };
    }) cfg.lowBatteryThresholds
  );

  dispatchScript = pkgs.writeShellScript "battery-notify-dispatch" ''
    if [ "$POWER_SUPPLY_ONLINE" = "1" ]; then
      echo 101 > "${lowBatteryStateFile}"
      ${notifyCharging}
    else
      ${notifyOnBattery}
    fi
  '';

  lowBatteryDispatchScript = pkgs.writeShellScript "battery-notify-low-dispatch" ''
    CAPACITY="$POWER_SUPPLY_CAPACITY"
    STATUS="$POWER_SUPPLY_STATUS"

    [ -n "$CAPACITY" ] || exit 0
    case "$CAPACITY" in
      *[!0-9]*) exit 0 ;;
    esac

    if [ "$STATUS" != "Discharging" ]; then
      echo 101 > "${lowBatteryStateFile}"
      exit 0
    fi

    LAST=$(cat "${lowBatteryStateFile}" 2>/dev/null || echo 101)
    case "$LAST" in
      *[!0-9]*) LAST=101 ;;
    esac

    TIER=""
    ${concatMapStringsSep "\n" (t: ''
      if [ -z "$TIER" ] && [ "$CAPACITY" -le ${toString t} ]; then
        TIER=${toString t}
      fi
    '') sortedThresholds}

    if [ -n "$TIER" ] && [ "$TIER" -lt "$LAST" ]; then
      echo "$TIER" > "${lowBatteryStateFile}"
      case "$TIER" in
        ${concatMapStringsSep "\n" (
          t: "${toString t}) ${lowBatteryNotifyScripts.${toString t}} ;;"
        ) sortedThresholds}
      esac
    fi
  '';
in
{
  options.modules.services.battery = {
    enable = mkEnableOption "notify on AC adapter plug/unplug and low battery";

    lowBatteryThresholds = mkOption {
      type = with types; listOf int;
      default = [
        50
        25
        10
        5
      ];
      description = ''
        Battery percentages to notify at while discharging. Only the lowest
        tier reached that hasn't already been notified fires, so this won't
        spam repeatedly at the same level.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ACTION=="change", ENV{POWER_SUPPLY_TYPE}=="Mains", RUN+="${dispatchScript}"
      SUBSYSTEM=="power_supply", ACTION=="change", ENV{POWER_SUPPLY_TYPE}=="Battery", RUN+="${lowBatteryDispatchScript}"
    '';
  };
}
