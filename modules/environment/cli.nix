{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  cfg = config.modules.environment.cli;
in
{
  options.modules.environment.cli = {
    enable = mkEnableOption "cli environment";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      # System
      pkgs.htop
      pkgs.openssl
      pkgs.file
      pkgs.unzip
      pkgs.unrar
      pkgs.curl

      # Text
      pkgs.kakoune
      pkgs.neovim
    ];
    
    environment = {
      variables = {
        EDITOR = "kak";
        VISUAL = "kak";
      };

      shellAliases = {
        vim = "nvim";
        vi = "nvim";
      };
    };

    shells = [ pkgs.zsh ];
    
    homeManager = {
      programs = {
        exa = {
          enable = true;
          enableAliases = true;
        };
      };
    };
  };
}
