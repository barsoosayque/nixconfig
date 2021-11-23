{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.system.keyboard;
  
  changeLayoutKeys = {
    CapsLocks = "grp:caps_toggle";
  };
in
{
  options.system.keyboard = {
    bindings = mkOption {
      type = types.attrs;
      default = {};
      description = "sxhkd-like keybinding definitions";
      example = literalExpression ''
      {
        "super + Return" = "alacritty";
        "super + d" = "launcher";
      }
      '';
    };

    layouts =  mkOption {
      type = types.listOf types.str;
      default = [ "us" "ru" ];
      description = "Keyboard layouts to use";
    };
    
    changeLayoutKey = mkOption {
      type = types.enum (attrNames changeLayoutKeys);
      default = "CapsLocks";
      description = "Key to change keyboard layout";
    };
  };

  config = {
    homeManager.home.keyboard = {
      layout = concatStringsSep "," cfg.layouts;
      options = [ changeLayoutKeys."${cfg.changeLayoutKey}" ];
    };
  };
}
