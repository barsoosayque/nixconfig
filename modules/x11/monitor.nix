{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (builtins) listToAttrs;
  inherit (attrsets) nameValuePair;
  inherit (strings) optionalString;
  inherit (lists) zipListsWith;

  cfg = config.modules.x11.monitor;

  resolutionSubmodule = types.submodule ({ ... }: {
    options = {
      width = mkOption {
        type = types.int;
        description = "Width of the monitor";
      };

      height = mkOption {
        type = types.int;
        description = "Height of the monitor";
      };
    };
  });

  layoutSubmodule = types.submodule ({ ... }: {
    options = {
      identifier = mkOption {
        type = types.str;
        description = "Xrandr monitor identifier";
      };

      resolution = mkOption {
        type = resolutionSubmodule;
        description = "Monitor resolution";
      };
    };
  });

  mkHead = head: prevHead:
    let
      mkLeftOfOption = head: ''
        Option "LeftOf" "${head.identifier}"
      '';
    in
    {
      output = head.identifier;
      monitorConfig = ''
        Option "PreferredMode" "${toString head.resolution.width}x${toString head.resolution.height}"
        ${optionalString (prevHead != null) (mkLeftOfOption prevHead)}
      '';
    };

  mkLayout = layout:
    [
      ((mkHead (head layout) null) // { primary = true; })
    ] ++ (zipListsWith mkHead (tail layout) layout);
in
{
  options.modules.x11.monitor = {
    layout =  mkOption {
      type = types.listOf layoutSubmodule;
      default = [];
      description = "Monitor configuration list";
    };
  };

  config = {
    # services.xserver.xrandrHeads = mkLayout cfg.layout;
  };
}
