{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    lists
    attrsets
    ;

  cfg = config.modules.environment.android;
in
{
  options.modules.environment.android = {
    enable = mkEnableOption "android environment";

    androidStudio = mkEnableOption "android studio IDE";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = lists.optional cfg.androidStudio [ pkgs.android-studio ];
    };

    programs.adb.enable = true;
    users.users."${config.system.user.name}".extraGroups = [ "adbusers" ];

    nixpkgs.config = attrsets.optionalAttrs cfg.androidStudio {
      android_sdk.accept_license = true; # Accept the Android SDK licence
    };

    environment.variables = {
      # Move .android from home
      ANDROID_USER_HOME = "${config.system.user.dirs.data.absolutePath}/android";
    };
  };
}
