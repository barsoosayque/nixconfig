{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkOption types literalExpression mkAliasDefinitions;
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

    kb_layout = mkOption {
      type = with types; str;
      readOnly = true;
      description = "Read-only string with layouts";
    };

    kb_options = mkOption {
      type = with types; listOf str;
      readOnly = true;
      description = "Read-only list of options";
    };
  };

  config = {
    system.keyboard = {
      kb_layout = concatStringsSep "," cfg.layouts;
      kb_options = [ changeLayoutKeys."${cfg.changeLayoutKey}" ];
    };
    system.user.hm.home.keyboard = {
      layout = mkAliasDefinitions options.system.keyboard.kb_layout;
      options = mkAliasDefinitions options.system.keyboard.kb_options;
    };
  };
}
