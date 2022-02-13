{ nixpkgs, pkgs, ... }:

with pkgs.lib;
let
  inherit (strings) hasPrefix;
  inherit (trivial) throwIfNot;

  types = {
    symlink = "symlink";
    regular = "regular";
    null = "null";
  };
in
{
  mkSymlinkDir = path: source:
    throwIfNot (hasPrefix "/" path) "mkSymlinkDir path must be absolute (It's ${path})"
    {
      _dirType = types.symlink;
      absolutePath = path;
      inherit source;
    };

  mkRegularDir = path:
    throwIfNot (hasPrefix "/" path) "mkRegularDir path must be absolute (It's ${path})"
    {
      _dirType = types.regular;
      absolutePath = path;
    };

  mkNullDir =
    {
      _dirType = "null";
      absolutePath = "/dev/null";
    };

  isSymlinkDir = dir:
    dir._dirType or null == types.symlink; 

  isRegularDir = dir:
    dir._dirType or null == types.regular;

  isNullDir = dir:
    dir._dirType or null == types.null;
}