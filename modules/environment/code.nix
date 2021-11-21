{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.modules.environment.code;
in
{
  options.modules.environment.code = {
    enable = mkEnableOption "code environment";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.clang-tools
      pkgs.helix
    ];
    
    homeManager = {
      programs = {
        vscode = {
          enable = true;
          package = pkgs.vscodium;
          extensions = with pkgs.vscode-extensions; [
            # TODO
          ];
        };

        git = {
          enable = true;

          userName = "barsoosayque";
          userEmail = "shtoshich@gmail.com";
        };
      };

    };
  };
}
