{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (builtins) mapAttrs;

  cfg = config.modules.programs.wezterm;
  pkg = pkgs.wezterm;
in
{
  options.modules.programs.wezterm = {
    enable = mkEnableOption "wezterm";
  };

  config = mkIf cfg.enable {
    system.keyboard.bindings = {
      "super + Return" = "${pkg}/bin/wezterm";
    };

    environment.systemPackages = [ pkg ];

    system.user.hm = {
      programs.wezterm = {
        enable = true;
        enableZshIntegration = true;

        package = pkg;

        colorSchemes = {
          nixos = {
            ansi = [
              config.system.pretty.theme.colors.normal.black.hexRGB
              config.system.pretty.theme.colors.normal.red.hexRGB
              config.system.pretty.theme.colors.normal.green.hexRGB
              config.system.pretty.theme.colors.normal.yellow.hexRGB
              config.system.pretty.theme.colors.normal.blue.hexRGB
              config.system.pretty.theme.colors.normal.magenta.hexRGB
              config.system.pretty.theme.colors.normal.cyan.hexRGB
              config.system.pretty.theme.colors.normal.white.hexRGB
            ];
            brights = [
              config.system.pretty.theme.colors.bright.black.hexRGB
              config.system.pretty.theme.colors.bright.red.hexRGB
              config.system.pretty.theme.colors.bright.green.hexRGB
              config.system.pretty.theme.colors.bright.yellow.hexRGB
              config.system.pretty.theme.colors.bright.blue.hexRGB
              config.system.pretty.theme.colors.bright.magenta.hexRGB
              config.system.pretty.theme.colors.bright.cyan.hexRGB
              config.system.pretty.theme.colors.bright.white.hexRGB
            ];
            background = config.system.pretty.theme.colors.primary.background.hexRGB;
            foreground = config.system.pretty.theme.colors.primary.foreground.hexRGB;
            cursor_bg = config.system.pretty.theme.colors.cursor.cursor.hexRGB;
            cursor_border = config.system.pretty.theme.colors.cursor.accent.hexRGB;
            cursor_fg = config.system.pretty.theme.colors.cursor.text.hexRGB;
            selection_bg = config.system.pretty.theme.colors.cursor.text.hexRGB;
            selection_fg = config.system.pretty.theme.colors.cursor.cursor.hexRGB;            
          };  
        };

        extraConfig = ''
          local config = wezterm.config_builder()

          config.front_end = "WebGpu"
          config.font = wezterm.font('${config.system.pretty.theme.fonts.primary.name}', { weight = "Regular", style = "Normal", stretch = "Normal" })
          config.font_size = 13.0
          config.color_scheme = 'nixos'
          config.automatically_reload_config = true
          config.freetype_load_target = "HorizontalLcd"
          config.hide_tab_bar_if_only_one_tab = true

          -- Window
          config.window_decorations = "RESIZE"
          config.window_background_opacity = 0.95
          config.window_padding = {
            left = "20",
            right = "20",
            top = "20",
            bottom = "20",
          }
          config.window_close_confirmation = 'NeverPrompt'

          return config
        '';
      };
    };

  };
}
