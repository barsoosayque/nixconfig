{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.battery;

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

  dispatchScript = pkgs.writeShellScript "battery-notify-dispatch" ''
    if [ "$POWER_SUPPLY_ONLINE" = "1" ]; then
      ${notifyCharging}
    else
      ${notifyOnBattery}
    fi
  '';
in
{
  options.modules.services.battery = {
    enable = mkEnableOption "notify on AC adapter plug/unplug";
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ACTION=="change", ENV{POWER_SUPPLY_TYPE}=="Mains", RUN+="${dispatchScript}"
    '';
  };
}
