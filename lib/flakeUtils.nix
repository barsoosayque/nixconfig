# Utility functions to use in the main flake.nix
# Mostly just scrappers
{ nixpkgs, pkgs, ... }:

let
  inherit (pkgs.lib) mapAttrsToList;
  inherit (pkgs.lib.lists) flatten;
  inherit (pkgs.lib.attrsets) optionalAttrs;
  inherit (builtins) pathExists readDir filter mapAttrs isFunction;

  mapDir = mapper: path:
    mapAttrs
      (n: v: let p = path + "/${n}"; in mapper p)
      (optionalAttrs (pathExists path) (readDir path));

  mapAllFiles = mapper: path:
    flatten
      (
        mapAttrsToList
          (n: v: let p = path + "/${n}"; in if v == "directory" then mapAllFiles mapper p else mapper p)
          (optionalAttrs (pathExists path) (readDir path))
      );

  collectHosts = path: attrs:
    mapDir (p: mkHost p attrs) path;

  collectModules = path: attrs:
    filter (v: isFunction v) (mapAllFiles import path);

  collectPackages = path: attrs:
    mapDir (p: import p attrs) path;

  mkHost = path: attrs@{ modulesPath, pkgsLocal, home-manager, localLib, ... }:
    let
      name = baseNameOf path;
    in
    nixpkgs.lib.nixosSystem {
      system = pkgs.system;

      modules = [
        {
          _module.args.pkgsLocal = pkgsLocal;
          _module.args.hostName = name;
          _module.args.hmLib = home-manager.lib;
          _module.args.localLib = localLib;
        }
        home-manager.nixosModule
        (path + "/system.nix")
        (path + "/hardware.nix")
      ] ++ (collectModules modulesPath { });

    };
in
{
  inherit collectHosts collectModules collectPackages;
}
