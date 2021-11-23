{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let 
  cfg = config.modules.programs.scissors;
  bin = "${pkgsLocal.scissors}/bin/scissors";
in
{
  options.modules.programs.scissors = {
    enable = mkEnableOption "scissors";
    
    screenshotsDir = mkOption {
      type = types.str;
      default = "$XDG_PICTURES_DIR/screenshots";
      description = "Directory to put screenshots to";
    };
  };

  config = mkIf cfg.enable {
    system.keyboard.bindings = {
      "{_,shift +} Print" = "${bin} -d ${cfg.screenshotsDir} {-s,_}";
    };
  };
}
