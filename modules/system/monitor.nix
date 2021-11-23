{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.system.monitor;
in
{
  options.system.monitor = {
    layouts =  mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Ordered list of monitors";
    };
  };

  config = {
  };
}
