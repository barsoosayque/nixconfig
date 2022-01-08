{ nixpkgs, pkgs, ... }:

with pkgs.lib;
let
  types = {
    symlink = "symlink";
    regular = "regular";
    null = "null";
  };
in
{
  mkSymlinkDir = path: source:
    {
      _dirType = types.symlink;
      inherit path source;
    };

  mkRegularDir = path:
    {
      _dirType = types.regular;
      inherit path;
    };

  mkNullDir =
    {
      _dirType = "null";
      path = "/dev/null";
    };

  isSymlinkDir = dir:
    dir._dirType or null == types.symlink; 

  isRegularDir = dir:
    dir._dirType or null == types.regular;

  isNullDir = dir:
    dir._dirType or null == types.null;
}