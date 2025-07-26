{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (lib.attrsets) nameValuePair;
  inherit (lib.strings) optionalString;
  inherit (lib.lists) zipListsWith;
  inherit (builtins) listToAttrs concatStringsSep head tail;

  cfg = config.modules.graphics.monitor;

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

  mkCmd = layout: dpi: "${pkgs.xorg.xrandr}/bin/xrandr --dpi ${toString dpi} ${mkOutputs layout};";
in
{
  options.modules.graphics.monitor = {
    layout = mkOption {
      type = with types; listOf layoutSubmodule;
      default = [ ];
      description = "Monitor configuration list";
    };

    dpi = mkOption {
      type = with types; int;
      default = 96;
      description = "Screen DPI";
    };
  };

  config = {
    system.events.onStartup = [
      (mkCmd cfg.layout cfg.dpi)
    ];
    services.xserver = {
      dpi = cfg.dpi;
      monitorSection = ''
        Option "DPI" "${toString cfg.dpi} x ${toString cfg.dpi}"
      '';
    };
    system.user.hm.xresources.properties = {
      "Xft.dpi" = cfg.dpi;
    };
  };
}
