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
      type = types.listOf types.str;
      default = [ ];
      description = "List of directories to create in storage root";
    };
  };

  config = {
    system.activationScripts =
      let
        mkStorageDirCmd = dir:
          ''
            install -d -m 1777 ${cfg.root}/${dir}
            chown '${cfg.user}:${cfg.group}' ${cfg.root}/${dir}
          '';
      in
      {
        createStorageRoot = mkStorageDirCmd "";

        createStorageDirs = ''
          ${concatStringsSep "\n" (map mkStorageDirCmd cfg.dirs)}
        '';
      };

    users = {
      users."${cfg.user}" = {
        group = cfg.group;
        description = "User files warehouse";
        isSystemUser = true;
      };

      groups."${cfg.group}" = { };
    };
  };
}
