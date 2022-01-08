input@{ nixpkgs, pkgs, ... }:

{
  flakeUtils = import ./flakeUtils.nix input;
  userDirsUtils = import ./userDirsUtils.nix input;
}
