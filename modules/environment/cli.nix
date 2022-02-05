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
    environment = {
      systemPackages = [
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
    
      variables = {
        EDITOR = "kak";
        VISUAL = "kak";
      };
    };

    users.defaultUserShell = pkgs.zsh;

    system.user.hm = {
      programs = {
        zsh = {
          enable = true;
          enableCompletion = true;
          enableSyntaxHighlighting = true;
          # TODO: absolute path
          dotDir = ".config/zsh";

          history = {
            ignoreDups = true;
            path = "${config.system.user.dirs.data.path}/zsh/history";
          };

          localVariables = {
            ENABLE_CORRECTION = true;
          };

          shellAliases = {
            vim = "nvim";
            vi = "nvim";
            mv = "mv -v";
            cp = "cp -v";
            ls = "${pkgs.exa}/bin/exa --icons --group-directories-first --classify ";
          };
        };
    
        exa = {
          enable = true;
        };
        bat = {
          enable = true;
        };
      };
    };
  };
}
