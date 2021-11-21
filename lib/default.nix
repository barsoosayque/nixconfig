{ nixpkgs, pkgs, ... }:

with pkgs.lib;
let
  mkHost = path: attrs@{ modulesPath, pkgsLocal, home-manager, ... }:
    let
      name = baseNameOf path;
    in
    nixpkgs.lib.nixosSystem {
      system = pkgs.system;

      modules = [
        {
          _module.args.pkgsLocal = pkgsLocal;
          _module.args.hostName = name;
        }
        home-manager.nixosModule
        (path + "/system.nix")
        (path + "/hardware.nix")
      ] ++ (mapAllFiles import modulesPath);
      
    };

  # Maps content of the directory.
  #
  # input:
  #   mapper: Path -> Any
  #     Mapper function to convert a path to something
  #   path: Path
  #     Path to the directory
  # output: AttrSet
  #   Set of { relative path = mapped value }
  mapDir = mapper: path:
    mapAttrs
    (n: v: let p = path + "/${n}"; in mapper p)
    (attrsets.optionalAttrs (builtins.pathExists path) (builtins.readDir path));
    
  mapAllFiles = mapper: path:
    lists.flatten
    (
      mapAttrsToList
      (n: v: let p = path + "/${n}"; in if v == "directory" then mapAllFiles mapper p else mapper p)
      (attrsets.optionalAttrs (builtins.pathExists path) (builtins.readDir path))
    );
in
{
  collectHosts = path: attrs:
    mapDir (p: mkHost p attrs) path;

  collectModules = path: attrs:
    mapAllFiles import path;

  collectPackages = path: attrs:
    mapDir (p: import p attrs) path;
}
