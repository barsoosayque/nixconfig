{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScriptBin;
  
  cfg = config.system.pretty;

  setrootBin = "${pkgs.setroot}/bin/setroot";

  themes = {
    fantasy = import ./themes/fantasy.nix;
  };
in
{
  options.system.pretty = {
    backgroundEnable = mkEnableOption "background management";

    themeName = mkOption {
      type = types.enum (attrNames themes);
      default = "fantasy";
      readOnly = true;
    };

    theme = mkOption {
      type = types.attrs;
      readOnly = true;
    };
  };

  config = let
    theme = themes."${cfg.themeName}";
  in {
    system.pretty.theme = theme;

    system.events.onStartup = lists.optional cfg.backgroundEnable
      "${setrootBin} --restore";
    
    environment.systemPackages = lists.optional cfg.backgroundEnable
      (writeScriptBin "background" "${setrootBin} --store $@");
  };
}
