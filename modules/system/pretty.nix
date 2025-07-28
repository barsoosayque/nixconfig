input@{ config, pkgs, pkgsRepo, lib, localLib /* For some reason, unless localLib is matched here, it won't be captured in input ???*/, ... }:

let
  inherit (lib) mkOption mkEnableOption types;
  inherit (lib.lists) optional;
  inherit (pkgs) writeScriptBin;
  inherit (builtins) attrNames;

  cfg = config.system.pretty;

  setrootBin = "${pkgs.setroot}/bin/setroot";

  themes = {
    fantasy = import ./themes/fantasy.nix input;
    atelier = import ./themes/atelier.nix input;
    sunset = import ./themes/sunset.nix input;
  };
in
{
  options.system.pretty = {
    backgroundEnable = mkEnableOption "background management";

    themeName = mkOption {
      type = with types; enum (attrNames themes);
      default = "sunset";
      readOnly = true;
    };

    theme = mkOption {
      type = with types; attrs;
      readOnly = true;
    };
  };

  config =
    let
      theme = themes."${cfg.themeName}";
    in
    {
      system.pretty.theme = theme;

      system.events.onWMLoaded = optional cfg.backgroundEnable
        "${setrootBin} --restore";

      # setroot generates a script to restore background images, but the script
      # assumes that setroot in PATH, and that's not the case within nixos
      environment.systemPackages = optional cfg.backgroundEnable
        (writeScriptBin "background" ''
          ${setrootBin} $@
          echo ${setrootBin} $@ > ~/.config/setroot/.setroot-restore
          chmod +x ~/.config/setroot/.setroot-restore
        '');
    };
}
