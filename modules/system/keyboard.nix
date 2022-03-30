{ config, pkgs, lib, ... }:

let
  inherit (lib) mkOption types literalExpression;
  inherit (builtins) concatStringsSep attrNames;

  cfg = config.system.keyboard;

  changeLayoutKeys = {
    CapsLocks = "grp:caps_toggle";
  };
in
{
  options.system.keyboard = {
    bindings = mkOption {
      type = with types; attrs;
      default = { };
      description = "sxhkd-like keybinding definitions";
      example = literalExpression ''
        {
          "super + Return" = "alacritty";
          "super + d" = "launcher";
        };
      '';
    };

    layouts = mkOption {
      type = with types; listOf str;
      default = [ "us" "ru" ];
      description = "Keyboard layouts to use";
    };

    changeLayoutKey = mkOption {
      type = with types; enum (attrNames changeLayoutKeys);
      default = "CapsLocks";
      description = "Key to change keyboard layout";
    };
  };

  config = {
    system.user.hm.home.keyboard = {
      layout = concatStringsSep "," cfg.layouts;
      options = [ changeLayoutKeys."${cfg.changeLayoutKey}" ];
    };
  };
}
