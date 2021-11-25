{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.modules.environment.code;

  codePkg = pkgs.vscodium;
in
{
  options.modules.environment.code = {
    enable = mkEnableOption "code environment";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.clang-tools
      pkgs.helix
      pkgs.git
      codePkg
    ];
    
    homeManager = {
      programs = {
        vscode = {
          enable = true;
          package = codePkg;
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
