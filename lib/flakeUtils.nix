# Utility functions to use in the main flake.nix
# Mostly just scrappers
{ nixpkgs, pkgs, pkgsRepo, ... }:

let
  inherit (pkgs.lib) mapAttrsToList makeOverridable;
  inherit (pkgs.lib.strings) hasSuffix;
  inherit (pkgs.lib.lists) flatten;
  inherit (pkgs.lib.attrsets) optionalAttrs;
  inherit (builtins) pathExists readDir filter mapAttrs isFunction;

  mapDir = mapper: path:
    mapAttrs
      (n: v: let p = path + "/${n}"; in mapper p)
      (optionalAttrs (pathExists path) (readDir path));

  mapAllFiles = mapper: path: depth:
    flatten
      (
        mapAttrsToList
          (n: v: let p = path + "/${n}"; in if v == "directory" then mapAllFiles mapper p (depth - 1) else mapper p)
          (optionalAttrs ((pathExists path) && depth >= 0) (readDir path))
      );

  collectHosts = path: attrs:
    mapDir (p: mkHost p attrs) path;

  collectModules = path: attrs:
    mapAllFiles (p: if hasSuffix ".nix" p then import p else {}) path 1;

  collectPackages = path: attrs:
    mapDir (p: makeOverridable (import p) attrs) path;

  mkHost = path: attrs@{ modulesPath, extraModules, home-manager, localLib, ... }:
    let
      name = baseNameOf path;
    in
    nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;

      modules = [
        {
          _module.args.pkgsRepo = pkgsRepo;
          _module.args.hostName = name;
          _module.args.hmLib = home-manager.lib;
          _module.args.localLib = localLib;
        }
        (path + "/system.nix")
        (path + "/hardware.nix")
      ] ++ (collectModules modulesPath { }) ++ extraModules;

    };
in
{
  inherit collectHosts collectModules collectPackages;
}
