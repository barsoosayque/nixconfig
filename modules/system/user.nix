{ config, options, pkgs, pkgsLocal, lib, hostName, hmLib, localLib, ... }:

with lib;
let
  inherit (strings) hasPrefix removePrefix;
  inherit (localLib.userDirsUtils) mkRegularDir mkSymlinkDir mkNullDir isRegularDir isSymlinkDir;
  
  cfg = config.system.user;
in
{
  options.system.user = {
    name = mkOption {
      type = types.str;
      description = "Main user name";
    };

    uid = mkOption {
      type = types.int;
      readOnly = true;
      description = "Main user uid";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra configs for current user (nixos user configs)";
    };

    hm = mkOption {
      type = types.attrs;
      default = {};
      description = "Home-manager configs for current user";
    };

    home = mkOption {
      type = types.str;
      readOnly = true;
      description = "Absolute path to the user's home";
    };

    dirs = mkOption {
      type = types.attrs;
      readOnly = true;
      description = "Set of user governed directories";
    };

    utils = {
      mkHomeDir = mkOption {
        type = types.functionTo types.attrs;
        readOnly = true;
        description = "Utility function to create a regular home directory (for system.user.dirs)";
      };

      mkStorageDir = mkOption {
        type = types.functionTo types.attrs;
        readOnly = true;
        description = "Utility function to create an external directory in storage and link it to home (for system.user.dirs)";
      };
    };
  };

  config = {
    users.users."${cfg.name}" = mkAliasDefinitions options.system.user.extraConfig;
    home-manager.users."${cfg.name}" = mkAliasDefinitions options.system.user.hm;
    
    system.user = {
      uid = 1000;
      home = "/home/${cfg.name}";

      extraConfig = {
        home = mkAliasDefinitions options.system.user.home;
        uid = mkAliasDefinitions options.system.user.uid;
        description = "The one and only";
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        passwordFile = "${cfg.dirs.config.path}/nixpass";
      };

      utils = {
        mkHomeDir = path:
          mkRegularDir "${cfg.home}/${path}";

        # FIXME: storage module
        mkStorageDir = path:
          mkSymlinkDir "${cfg.home}/${path}" "${cfg.home}/.local/storage";
      };

      dirs = {
        # sdd dirs
        work = cfg.utils.mkHomeDir "work";
        games = cfg.utils.mkHomeDir "games";
        data = cfg.utils.mkHomeDir ".local/share";
        config = cfg.utils.mkHomeDir ".config";
        desktop = mkNullDir;
        publicShare = mkNullDir;
        templates = mkNullDir;

        # hdd dirs
        documents = cfg.utils.mkStorageDir "documents";
        download = cfg.utils.mkStorageDir "downloads";
        music = cfg.utils.mkStorageDir "music";
        pictures = cfg.utils.mkStorageDir "pictures";
        videos = cfg.utils.mkStorageDir "videos";
      };

      hm = {
        home.activation = {
          mkUserDirs = 
            let
              dirs = filter isRegularDir (attrValues cfg.dirs);
            in
              hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD mkdir -p ${concatStringsSep " " (map (d: d.path) dirs)}
              '';
          
          linkUserDirs =
            let
              dirs = filter isSymlinkDir (attrValues cfg.dirs);
              
              linkCmd = dir:
                "$DRY_RUN_CMD [ ! -L ${dir.path} ] && ln -s ${dir.source} ${dir.path}";
            in
              hmLib.hm.dag.entryAfter [ "writeBoundary" "mkuser.dirs" ] 
                (concatStringsSep "\n" (map linkCmd dirs));
        };

        xdg = {
          enable = true;

          userDirs = {
            desktop = cfg.dirs.desktop.path;
            publicShare = cfg.dirs.publicShare.path;
            templates = cfg.dirs.templates.path;
            documents = cfg.dirs.documents.path;
            download = cfg.dirs.download.path;
            music = cfg.dirs.music.path;
            pictures = cfg.dirs.pictures.path;
            videos = cfg.dirs.videos.path;

            enable = true;
            createDirectories = false;
          };
        };
      };
    };
  };
}
