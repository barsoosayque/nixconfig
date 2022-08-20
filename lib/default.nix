input@{ nixpkgs, pkgs, ... }:

{
  flakeUtils = import ./flakeUtils.nix input;
  userDirsUtils = import ./userDirsUtils.nix input;
  colorUtils = import ./colorUtils.nix input;
}
