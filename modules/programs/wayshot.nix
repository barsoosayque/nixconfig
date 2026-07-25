{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.modules.programs.wayshot;

  mkCapture =
    name: geometryArgs:
    pkgs.writeShellScript "wayshot-${name}" ''
      dir="${cfg.screenshotsDir}/$(date +%Y)/$(date +%m)"
      mkdir -p "$dir"
      ${pkgs.wayshot}/bin/wayshot ${geometryArgs} --cursor --clipboard --silent "$dir"
      ${config.system.events.onScreenshotScript}
    '';
in
{
  options.modules.programs.wayshot = {
    enable = mkEnableOption "wayshot";

    screenshotsDir = mkOption {
      type = with types; str;
      default = "${config.system.user.dirs.pictures.absolutePath}/screenshots";
      description = "Directory to put screenshots to, organized into <dir>/<year>/<month>";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wayshot ];

    system.keyboard.bindings = {
      "super + shift + s" = mkCapture "full" "";
      "super + s" = mkCapture "region" "-g";
    };
  };
}
