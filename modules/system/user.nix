{ config, options, pkgs, lib, hostName, hmLib, localLib, ... }:

let
  inherit (lib) mkOption mkAliasDefinitions types;
  inherit (lib.strings) hasPrefix removePrefix;
  inherit (localLib.userDirsUtils) mkRegularDir mkSymlinkDir mkNullDir isRegularDir isSymlinkDir;
  inherit (builtins) filter attrValues concatStringsSep;

  cfg = config.system.user;
in
{
  options.system.user = {
    name = mkOption {
      type = with types; str;
      description = "Main user name";
    };

    uid = mkOption {
      type = with types; int;
      readOnly = true;
      description = "Main user uid";
    };

    extraConfig = mkOption {
      type = with types; attrs;
      default = { };
      description = "Extra configs for current user (nixos user configs)";
    };

    hm = mkOption {
      type = with types; attrs;
      default = { };
      description = "Home-manager configs for current user";
    };

    home = mkOption {
      type = with types; str;
      readOnly = true;
      description = "Absolute path to the user's home";
    };

    dirs = mkOption {
      type = with types; attrs;
      readOnly = true;
      description = "Set of user governed directories";
    };

    utils = {
      mkHomeDir = mkOption {
        type = with types; functionTo attrs;
        readOnly = true;
        description = "Utility function to create a regular home directory (for system.user.dirs)";
      };

      mkStorageDir = mkOption {
        type = with types; functionTo attrs;
        readOnly = true;
        description = "Utility function to create an external directory in storage and link it to home (for system.user.dirs)";
      };
    };
  };

  config = rec {
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
        passwordFile = "${cfg.dirs.config.absolutePath}/nixos/nixpass";
      };

      utils = {
        mkHomeDir = path:
          (mkRegularDir "${cfg.home}/${path}") // { relativePath = "${path}"; };

        mkStorageDir = path:
          (mkSymlinkDir "${cfg.home}/${path}" "${config.system.storage.root}/${path}") // { relativePath = "${path}"; };
      };

      dirs = {
        # sdd dirs
        games = cfg.utils.mkHomeDir "games";
        data = cfg.utils.mkHomeDir ".local/share";
        config = cfg.utils.mkHomeDir ".config";
        desktop = mkNullDir;
        publicShare = mkNullDir;
        templates = mkNullDir;

        # hdd dirs
        work = cfg.utils.mkStorageDir "work";
        documents = cfg.utils.mkStorageDir "documents";
        download = cfg.utils.mkStorageDir "downloads";
        music = cfg.utils.mkStorageDir "music";
        pictures = cfg.utils.mkStorageDir "pictures";
        videos = cfg.utils.mkStorageDir "videos";
      };

      hm = {
        home = {
          stateVersion = config.system.stateVersion;
          activation = {
            createUserDirs =
              let
                dirs = filter isRegularDir (attrValues cfg.dirs);
              in
              hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD mkdir -p ${concatStringsSep " " (map (d: d.absolutePath) dirs)}
              '';

            linkUserDirs =
              let
                dirs = filter isSymlinkDir (attrValues cfg.dirs);

                linkCmd = dir:
                  "$DRY_RUN_CMD [ ! -L ${dir.absolutePath} ] && ln -s ${dir.source} ${dir.absolutePath}";
              in
              hmLib.hm.dag.entryAfter [ "writeBoundary" "createUserDirs" ]
                (concatStringsSep "\n" (map linkCmd dirs));
          };
        };

        xdg = {
          enable = true;

          userDirs = {
            desktop = cfg.dirs.desktop.absolutePath;
            publicShare = cfg.dirs.publicShare.absolutePath;
            templates = cfg.dirs.templates.absolutePath;
            documents = cfg.dirs.documents.absolutePath;
            download = cfg.dirs.download.absolutePath;
            music = cfg.dirs.music.absolutePath;
            pictures = cfg.dirs.pictures.absolutePath;
            videos = cfg.dirs.videos.absolutePath;

            enable = true;
            createDirectories = false;
          };
        };
      };
    };

    # Collect storage dirs
    system.storage.dirs =
      let
        storageRoot = config.system.storage.root;
        allDirs = attrValues config.system.user.dirs;

        dirFilter = d: (isSymlinkDir d) && (hasPrefix storageRoot d.source);
        filtered = filter dirFilter allDirs;

        storageDirs = map (d: removePrefix storageRoot d.source) filtered;
      in
      storageDirs;
  };
}
