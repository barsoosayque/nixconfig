{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.environment.android;
in
{
  options.modules.environment.android = {
    enable = mkEnableOption "android environment";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [ pkgs.android-studio ];
    };

    programs.adb.enable = true;
    nixpkgs.config = {
      android_sdk.accept_license = true; # Accept the Android SDK licence
    };
  };
}
