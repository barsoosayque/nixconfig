{ config, pkgs, pkgsRepo, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.modules.programs.scissors;
  bin = "${pkgsRepo.local.scissors}/bin/scissors";
in
{
  options.modules.programs.scissors = {
    enable = mkEnableOption "scissors";

    screenshotsDir = mkOption {
      type = with types; str;
      default = "${config.system.user.dirs.pictures.absolutePath}/screenshots";
      description = "Directory to put screenshots to";
    };
  };

  config = mkIf cfg.enable {
    system.keyboard.bindings = {
      "{_,shift +} Print" = "${bin} -d ${cfg.screenshotsDir} {-s,_} -x ${config.system.events.onScreenshotScript}";
    };
  };
}
