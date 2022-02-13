{ config, options, pkgs, pkgsLocal, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (lib.lists) optionals;
  inherit (pkgs.vscode-utils) extensionsFromVscodeMarketplace;

  cfg = config.modules.environment.code;

  codePkg = pkgs.vscodium;
in
{
  options.modules.environment.code = {
    enable = mkEnableOption "code environment";

    enableRust = mkOption {
      type = with types; bool;
      default = true;
      description = "Enable Rust environment";
    };
  };

  config = mkIf cfg.enable {
    fonts.fonts = [ pkgs.fira-code ];

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    environment.systemPackages = [
      pkgs.rnix-lsp
      pkgs.direnv

      pkgs.cmake
      pkgs.gnumake
      pkgs.clang
      pkgs.clang-tools
      pkgs.git

      codePkg
    ] ++ optionals cfg.enableRust [ pkgs.rls pkgs.rustfmt ];

    system.user.hm = {
      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        vscode = {
          enable = true;
          package = codePkg;
          extensions = with pkgs.vscode-extensions; [
            pkief.material-icon-theme
            tamasfe.even-better-toml
            asciidoctor.asciidoctor-vscode

            # requires rnix-lsp
            jnoortheen.nix-ide
          ] ++ extensionsFromVscodeMarketplace [
            {
              name = "aura-theme";
              publisher = "DaltonMenezes";
              version = "2.1.0";
              sha256 = "c0f9682ee3faa4a18e7f23455b0cc9e402e5ccd74aa9e0f6a4a0a7e9255d2f9f";
            }
            {
              name = "dance";
              publisher = "gregoire";
              version = "0.5.8";
              sha256 = "aa18916e40ca512277cd66e5b324b9bde2a52658087b61250f7e42c72826bda0";
            }
            {
              name = "vscode-direnv";
              publisher = "cab404";
              version = "1.0.0";
              sha256 = "fa72c7f93f6fe93402a8a670e873cdfd97af43ae45566d92028d95f5179c3376";
            }
          ] ++ optionals cfg.enableRust [
            vadimcn.vscode-lldb
            matklad.rust-analyzer
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
