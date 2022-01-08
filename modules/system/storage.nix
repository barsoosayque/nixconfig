{ config, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.system.storage;
in
{
  options.system.storage = {
    user = mkOption {
      type = types.str;
      default = "storage";
      description = "Storage user name";
    };
    
    group = mkOption {
      type = types.str;
      default = "storage";
      description = "Storage user group";
    };

    root = mkOption {
      type = types.str;
      default = "/storage";
      description = "Absolute path to storage root";
    };

    dirs = mkOption {
      type = types.attrs;
      default = {};
      description = "Set of directories to create";
    };
  };

  config =  {
    system.activationScripts = { 
      storageDirectory = ''
        install -d -m 1777 ${cfg.root}
        chown '${cfg.user}:${cfg.group}' ${cfg.root}
      '';
    };
    
    users = {
      users."${cfg.user}" = {
        group = cfg.group;
        description = "User files warehouse";
        isSystemUser = true;
      };

      groups."${cfg.group}" = {};
    };
  };
}
