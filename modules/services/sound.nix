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
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = false;
    };
  };
}
