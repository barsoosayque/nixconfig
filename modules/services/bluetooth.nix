{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.bluetooth;
in
{
  options.modules.services.bluetooth = {
    enable = mkEnableOption "bluetooth";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings = {
      General = {
        # TODO: why ? something with pipewire
        Enable = "Source,Sink,Media,Socket";

        # https://wiki.archlinux.org/title/Bluetooth#Continually_connect/disconnect_with_tp-link_UB400_and_xbox_controller
        # JustWorksRepairing = "always";
        # FastConnectable = true;
        # Class = "0x000100";
        # Privacy = "device";
      };

      # GATT = {
      #   ReconnectIntervals = "1,1,2,3,5,8,13,21,34,55";
      #   AutoEnable = true;
      # };

      # https://github.com/atar-axis/xpadneo/issues/295
      # LE = {
      #   MinConnectionInterval = 7;
      #   MaxConnectionInterval = 9;
      #   ConnectionLatency = 0;
      # };
    };
    services.blueman.enable = true;
  };
}
