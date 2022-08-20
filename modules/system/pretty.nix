input@{ config, pkgs, pkgsRepo, lib, localLib /* For some reason, unless localLib is matched here, it won't be captured in input ???*/, ... }:

let
  inherit (lib) mkOption mkEnableOption types;
  inherit (lib.lists) optional;
  inherit (pkgs) writeScriptBin;
  inherit (builtins) attrNames;

  cfg = config.system.pretty;

  # setroot is broken at the moment
  setrootBin = "${pkgsRepo.stable.setroot}/bin/setroot";

  themes = {
    fantasy = import ./themes/fantasy.nix input;
  };
in
{
  options.system.pretty = {
    backgroundEnable = mkEnableOption "background management";

    themeName = mkOption {
      type = with types; enum (attrNames themes);
      default = "fantasy";
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

      system.events.onStartup = optional cfg.backgroundEnable
        "${setrootBin} --restore";

      environment.systemPackages = optional cfg.backgroundEnable
        (writeScriptBin "background" "${setrootBin} --store $@");
    };
}
