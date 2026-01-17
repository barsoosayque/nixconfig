{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption lists;

  cfg = config.modules.environment.cli;
in
{
  options.modules.environment.cli = {
    enable = mkEnableOption "cli environment";

    enableFlexing = mkEnableOption "cli tools to make pretty screenshots";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [
        # System
        pkgs.htop
        pkgs.iotop
        pkgs.bottom
        pkgs.openssl
        pkgs.file
        pkgs.unzip
        pkgs.unrar
        pkgs.curl
        pkgs.xclip
        pkgs.sad
        pkgs.fzf
        pkgs._7zz

        # Utility
        pkgs.imagemagick 

        # Text
        pkgs.neovim
      ] ++ lists.optionals cfg.enableFlexing [
        pkgs.neofetch
        pkgs.pipes
        pkgs.terminal-parrot
        pkgs.cbonsai
      ];

      variables = {
        EDITOR = "hx";
        VISUAL = "hx";
      };

      # https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.enableCompletion
      pathsToLink = [ "/share/zsh" ];
    };

    users.defaultUserShell = pkgs.zsh;

    programs.zsh.enable = true;

    system.user.hm = {
      programs = {
        nnn = {
          enable = true;          
          package = pkgs.nnn.override { 
            withNerdIcons = true;
          };
          bookmarks = {
            s = "${config.system.user.dirs.data.absolutePath}";
            c = "${config.system.user.dirs.config.absolutePath}";
            w = "${config.system.user.dirs.work.absolutePath}";
            d = "${config.system.user.dirs.documents.absolutePath}";
            D = "${config.system.user.dirs.download.absolutePath}";
            m = "${config.system.user.dirs.music.absolutePath}";
            p = "${config.system.user.dirs.pictures.absolutePath}";
            v = "${config.system.user.dirs.videos.absolutePath}";
          };
        };

        zsh = {
          enable = true;
          enableCompletion = true;
          syntaxHighlighting.enable = true;
          autosuggestion.enable = true;
          dotDir = "${config.system.user.dirs.data.absolutePath}/zsh";
          autosuggestion.strategy = [ "history" "completion" ];
          defaultKeymap = "viins";

          history = {
            ignoreDups = true;
            path = "${config.system.user.dirs.data.absolutePath}/zsh/history";
          };

          localVariables = {
            ENABLE_CORRECTION = true;
            PROMPT = "%# [%B%F{yellow}%n%f@%F{blue}%m%f%b] %F{green}%~%f: ";
          };

          shellAliases = {
            vim = "nvim";
            vi = "nvim";
            mv = "mv -v";
            cp = "cp -v";
            ls = "${pkgs.eza}/bin/exa --icons --group-directories-first --classify ";
          };
        };

        # exa = {
        #   enable = true;
        # };
        bat = {
          enable = true;
        };
      };
    };
  };
}
