{ config, options, pkgs, pkgsRepo, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.services.sound;
in
{
  options.modules.services.sound = {
    enable = mkEnableOption "sound";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pavucontrol ];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = false;
      media-session.enable = true;

      media-session.config.bluez-monitor = {
        properties = {
          bluez5.enable-msbc = true;
          bluez5.enable-sbc-xq = true;
          bluez5.codecs = [ "sbc" "sbc_xq" ];
          bluez5.default.rate = 44100;
          bluez5.default.channels = 2;
        };
      };
    };
  };
}
