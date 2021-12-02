{ nixpkgs, pkgs, ... }:

with pkgs.lib;
let
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
    
  collectHosts = path: attrs:
    mapDir (p: mkHost p attrs) path;

  collectModules = path: attrs:
    filter (v: isFunction v) (mapAllFiles import path);

  collectPackages = path: attrs:
    mapDir (p: import p attrs) path;

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
      ] ++ (collectModules modulesPath {});
      
    };
in
{
  inherit collectHosts collectModules collectPackages;
}
