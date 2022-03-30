{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (lib.attrsets) nameValuePair;
  inherit (lib.strings) optionalString;
  inherit (lib.lists) zipListsWith;
  inherit (builtins) listToAttrs concatStringsSep head tail;

  cfg = config.modules.x11.monitor;

  resolutionSubmodule = types.submodule ({ ... }: {
    options = {
      width = mkOption {
        type = with types; int;
        description = "Width of the monitor";
      };

      height = mkOption {
        type = with types; int;
        description = "Height of the monitor";
      };
    };
  });

  layoutSubmodule = types.submodule ({ ... }: {
    options = {
      identifier = mkOption {
        type = with types; str;
        description = "Xrandr monitor identifier";
      };

      resolution = mkOption {
        type = resolutionSubmodule;
        description = "Monitor resolution";
      };
    };
  });

  mkOutput = head: prevHead:
    ''
      --output ${head.identifier} \
      --mode ${toString head.resolution.width}x${toString head.resolution.height} \
      ${optionalString (prevHead != null) "--right-of ${prevHead.identifier}"} \
    '';

  mkOutputs = layout:
    concatStringsSep "" ([
      (mkOutput (head layout) null)
    ] ++ (zipListsWith mkOutput (tail layout) layout));

  mkCmd = layout: "${pkgs.xorg.xrandr}/bin/xrandr ${mkOutputs layout} ;";
in
{
  options.modules.x11.monitor = {
    layout = mkOption {
      type = with types; listOf layoutSubmodule;
      default = [ ];
      description = "Monitor configuration list";
    };
  };

  config = {
    system.events.onStartup = [
      (mkCmd cfg.layout)
    ];
  };
}
