{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    strings
    lists
    ;
  inherit (builtins) elemAt;

  cfg = config.modules.graphics.niri;

  wpaperctl = "${pkgs.wpaperd}/bin/wpaperctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  niri = "${config.programs.niri.package}/bin/niri";

  # Resize the focused window to a picked 16:9 resolution (logical pixels).
  resizeWindow = pkgs.writeShellScript "niri-resize-window" ''
    choice="$(printf '360p\n480p\n720p\n1080p\n1440p\n' \
      | ${pkgs.tofi}/bin/tofi ${config.modules.programs.tofi.args} --prompt-text '  Resize: ')"
    [ -z "$choice" ] && exit 0

    case "$choice" in
      360p)  w=640  h=360  ;;
      480p)  w=854  h=480  ;;
      720p)  w=1280 h=720  ;;
      1080p) w=1920 h=1080 ;;
      1440p) w=2560 h=1440 ;;
      *) exit 0 ;;
    esac

    ${niri} msg action set-window-width "$w"
    ${niri} msg action set-window-height "$h"
  '';

  # Pick a resolution, then a refresh rate, then a scale for the focused
  # output. Everything is applied over IPC, so nothing is written to the
  # config: the output reverts to its `output` block on the next config
  # reload. Each menu is built from what the output actually advertises, so
  # the same binding behaves sensibly on the laptop panel and on an external.
  resizeOutput = pkgs.writeShellScript "niri-resize-output" ''
    export LC_ALL=C
    jq="${pkgs.jq}/bin/jq"
    menu() { ${pkgs.tofi}/bin/tofi ${config.modules.programs.tofi.args} --prompt-text "$1"; }

    info="$(${niri} msg --json focused-output)" || exit 1
    name="$(    printf '%s' "$info" | "$jq" -r '.name')"
    maxw="$(    printf '%s' "$info" | "$jq" -r '[.modes[].width]  | max')"
    maxh="$(    printf '%s' "$info" | "$jq" -r '[.modes[].height] | max')"
    maxhz="$(   printf '%s' "$info" | "$jq" -r '[.modes[].refresh_rate] | max / 1000 | round')"
    cur="$(     printf '%s' "$info" | "$jq" -r '.modes[.current_mode] | "\(.width)x\(.height)"')"
    curhz="$(   printf '%s' "$info" | "$jq" -r '.modes[.current_mode].refresh_rate / 1000 | round')"
    curscale="$(printf '%.2f' "$(printf '%s' "$info" | "$jq" -r '.logical.scale')")"

    # Append a bullet when the entry is what the output is using right now.
    mark() { [ "$1" = "$2" ] && printf '  ●'; printf '\n'; }

    ## 1. resolution
    emit() {
      res="$1"
      aspect="$2"
      w="''${res%x*}"
      h="''${res#*x}"
      # Never offer more than the output can actually drive.
      [ "$w" -gt "$maxw" ] && return 0
      [ "$h" -gt "$maxh" ] && return 0
      printf '%-9s  %-5s' "$res" "$aspect"
      mark "$res" "$cur"
    }

    pick="$(
      {
        for r in 854x480 1280x720 1600x900 1920x1080 2560x1440; do emit "$r" "16:9"; done
        for r in 768x480 1280x800 1440x900 1680x1050 1920x1200 2560x1600; do emit "$r" "16:10"; done
        printf 'auto (preferred)\n'
      } | menu "  $name  ·  resolution: "
    )"
    [ -z "$pick" ] && exit 0
    case "$pick" in
      auto*) res="auto" ;;
      *)     read -r res _rest <<< "$pick" ;;
    esac

    ## 2. refresh rate — advertised rates for that resolution, plus 60 and the max
    if [ "$res" = "auto" ]; then
      hz=""
    else
      w="''${res%x*}"
      h="''${res#*x}"
      pick="$(
        {
          printf '%s' "$info" | "$jq" -r --argjson w "$w" --argjson h "$h" \
            '.modes[] | select(.width == $w and .height == $h) | .refresh_rate / 1000 | round'
          printf '60\n%s\n' "$maxhz"
        } | sort -rn | uniq | while read -r r; do
              printf '%sHz' "$r"
              mark "$r" "$curhz"
            done | menu "  $res  ·  refresh: "
      )"
      [ -z "$pick" ] && exit 0
      read -r hz _rest <<< "$pick"
      hz="''${hz%Hz}"
    fi

    ## 3. scale
    pick="$(
      for s in 0.5 0.75 1.0 1.25 1.5; do
        printf '%-5s' "$s"
        mark "$(printf '%.2f' "$s")" "$curscale"
      done | menu "  $res  ·  scale: "
    )"
    [ -z "$pick" ] && exit 0
    read -r scale _rest <<< "$pick"

    ## apply
    if [ "$res" = "auto" ]; then
      ${niri} msg output "$name" mode auto
    else
      # Prefer a real advertised mode (exact refresh, driver timings) and only
      # fall back to a synthesized CVT mode when the panel doesn't list one.
      exact="$(printf '%s' "$info" | "$jq" -r \
        --argjson w "$w" --argjson h "$h" --argjson hz "$hz" '
          [ .modes[] | select(.width == $w and .height == $h) | .refresh_rate / 1000 ]
          | map(select(((. - $hz) | fabs) < 1.5))
          | if length > 0 then (.[0] | tostring) else empty end
        ')"
      if [ -n "$exact" ]; then
        ${niri} msg output "$name" mode "''${res}@''${exact}"
      else
        ${niri} msg output "$name" custom-mode "''${res}@''${hz}"
      fi
    fi
    ${niri} msg output "$name" scale "$scale"
  '';

  # Connectors that start off until picked with Mod+Shift+C. niri remembers IPC
  # changes across hotplug, so one left on comes back on when replugged.
  externalOutputs = [
    "HDMI-A-1"
    "HDMI-A-2"
    "DP-1"
    "DP-2"
    "DP-3"
    "DP-4"
    "DP-5"
    "DP-6"
  ];

  # Run a niri action ($1) on the "external" workspace, making sure the output
  # ($2, default the first external one that's on) holds it first. It can't be
  # left to the picker: an output that comes back on by itself skips it.
  externalWorkspace = pkgs.writeShellScript "niri-external-workspace" ''
    jq="${pkgs.jq}/bin/jq"

    name="''${2:-$(${niri} msg --json outputs | "$jq" -r '
      [ .[] | select(.name != "eDP-1" and .logical != null) ][0].name // empty
    ')}"
    if [ -n "$name" ]; then
      cur="$(${niri} msg --json workspaces | "$jq" -r '.[] | select(.name == "external") | .output')"
      if [ -z "$cur" ]; then
        prev="$(${niri} msg --json focused-output | "$jq" -r '.name')"
        ${niri} msg action focus-monitor "$name"
        ${niri} msg action set-workspace-name external
        ${niri} msg action focus-monitor "$prev"
      elif [ "$cur" != "$name" ]; then
        # A leftover "external" (e.g. after a plain unplug): reuse it instead
        # of naming a second one.
        ${niri} msg action move-workspace-to-monitor --reference external "$name"
      fi
    fi

    ${niri} msg action "$1" external
  '';

  # Pick a connected external output, then where to put it (or turn it off).
  # The "external" workspace (Mod+0) only exists while an external output is
  # on: connecting names that output's workspace, turning it off unnames it
  # first, so it doesn't linger on the laptop panel (its windows still move
  # over as a plain workspace). Like resizeOutput this is IPC only, so a config
  # reload turns the external off again.
  connectOutput = pkgs.writeShellScript "niri-connect-output" ''
    export LC_ALL=C
    jq="${pkgs.jq}/bin/jq"
    menu() { ${pkgs.tofi}/bin/tofi ${config.modules.programs.tofi.args} --prompt-text "$1"; }

    outputs="$(${niri} msg --json outputs)" || exit 1

    ## 1. output
    pick="$(
      printf '%s' "$outputs" | "$jq" -r '
        .[] | select(.name != "eDP-1")
        | "\(.name)  \(.model)\(if .logical then "  ●" else "" end)"
      ' | menu "  connect: "
    )"
    [ -z "$pick" ] && exit 0
    read -r name _rest <<< "$pick"

    ## 2. placement
    pick="$(printf 'right\nleft\nabove\nbelow\noff\n' | menu "  $name: ")"
    [ -z "$pick" ] && exit 0

    if [ "$pick" = "off" ]; then
      ${niri} msg action unset-workspace-name external
      ${niri} msg output "$name" off
      exit 0
    fi

    ${niri} msg output "$name" on
    # Sizes are logical, so read them after the output is up.
    outputs="$(${niri} msg --json outputs)"
    geometry() { printf '%s' "$outputs" | "$jq" -r --arg n "$1" ".[\$n].logical | \"\(.x) \(.y) \(.width) \(.height)\""; }
    read -r lx ly lw lh <<< "$(geometry eDP-1)"
    read -r _ _ ew eh <<< "$(geometry "$name")"

    # Relative to where the panel is now: it isn't always at the origin.
    case "$pick" in
      right) x=$((lx + lw)) y="$ly" ;;
      left)  x=$((lx - ew)) y="$ly" ;;
      above) x="$lx"        y=$((ly - eh)) ;;
      below) x="$lx"        y=$((ly + lh)) ;;
      *) exit 0 ;;
    esac
    ${niri} msg output "$name" position set -- "$x" "$y"

    ${externalWorkspace} focus-workspace "$name"
  '';

  # Convert sxhkd key combo to niri format
  # "super + d" -> "Mod+D"
  # "super + shift + q" -> "Mod+Shift+Q"
  sxhkdKeyToNiri =
    keyStr:
    let
      parts = strings.splitString " + " keyStr;
      convertedParts = lists.map (
        part:
        if part == "super" then
          "Mod"
        else if part == "shift" then
          "Shift"
        else if part == "ctrl" || part == "control" then
          "Ctrl"
        else if part == "alt" then
          "Alt"
        else
          strings.toUpper part
      ) parts;
    in
    strings.concatStringsSep "+" convertedParts;

  # Split action string into list of arguments
  # "bemenu --fg #fff" -> [ "bemenu" "--fg" "#fff" ]
  splitAction =
    action:
    let
      parts = strings.splitString " " action;
      filtered = lists.filter (s: s != "") parts;
    in
    filtered;

  # Convert sxhkd bindings to niri config string
  # Returns lines indented by 2 spaces (for inside binds { } block)
  toNiriBinds =
    bindings:
    let
      convertOne =
        key: action:
        let
          niriKey = sxhkdKeyToNiri key;
          args = splitAction action;
          spawnArgs = strings.concatStringsSep " " (lists.map (a: "\"${a}\"") args);
        in
        "${niriKey} { spawn ${spawnArgs}; }";

      lines = lib.mapAttrsToList convertOne bindings;
    in
    strings.concatStringsSep "\n" lines;
in
{
  options.modules.graphics.niri = {
    enable = mkEnableOption "niri";

    windowRules = mkOption {
      type = with types; listOf lines;
      default = [ ];
      description = "Extra niri window-rule blocks, so each program module can ship its own.";
    };

    screenshotsDir = mkOption {
      type = with types; str;
      default = "${config.system.user.dirs.pictures.absolutePath}/screenshots";
      description = "Directory to put screenshots to, organized into <dir>/<year>/<month>";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wl-clipboard-rs
      pkgs.phinger-cursors
      # pkgs.xorg.xrdb
    ];

    programs.niri = {
      enable = true;
      useNautilus = true;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${config.programs.niri.package}/bin/niri-session";
          user = config.system.user.name;
        };
      };
    };

    security.polkit.enable = true;
    services.playerctld.enable = true;

    environment.sessionVariables = {
      # use integrated gpu for niri
      # WLR_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card1";
      # AQ_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card1";

      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # WLR_NO_HARDWARE_CURSORS = "1";
      # WLR_BACKEND = "vulkan";
      # XDG_SESSION_TYPE = "wayland";
      # QT_QPA_PLATFORM = "wayland";
      # CLUTTER_BACKEND = "wayland";
      # GDK_BACKEND = "wayland";
      # SDL_VIDEODRIVER = "wayland";
    };

    system.user.hm = {
      xdg.configFile."niri/config.kdl".text = ''
        spawn-at-startup "${pkgs.bash}/bin/bash" "-c" "${config.system.events.onWMLoadedScript}"

        prefer-no-csd

        screenshot-path "${cfg.screenshotsDir}/%Y/%m/Screenshot from %Y-%m-%d %H-%M-%S.png"

        xwayland-satellite {
          path "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        }

        environment {
          _JAVA_AWT_WM_NONREPARENTING "1"
          ELECTRON_OZONE_PLATFORM_HINT "auto"
        }

        hotkey-overlay {
          skip-at-startup
        }

        layout {
          gaps 20
          struts {
            left 00
            right 00
            top 00
            bottom 00
          }
          always-center-single-column
          // center-focused-column "on-overflow"
          default-column-display "tabbed"
          tab-indicator {
            hide-when-single-tab
            width 8
            gap 8
            length total-proportion=1.0
            position "top"
            place-within-column
          }
          default-column-width { proportion 0.8; }
          focus-ring {
            width 1;
            inactive-color "${config.system.pretty.theme.colors.window.border.hexRGBA}";
            active-color   "${config.system.pretty.theme.colors.window.active_border.hexRGBA}";
            urgent-color   "${config.system.pretty.theme.colors.window.urgent_border.hexRGBA}";
          }
          shadow {
            on
            softness 25;
            spread 0;
            offset x=0 y=0;
            draw-behind-window false;
            color "${config.system.pretty.theme.colors.window.shadow.hexRGBA}";
          }
          insert-hint {
            color "${config.system.pretty.theme.colors.cursor.accent.hexRGB}80";
          }
        }

        window-rule {
          geometry-corner-radius 2
          clip-to-geometry true
        }

        ${strings.concatStringsSep "\n" cfg.windowRules}

        input {
          keyboard {
            xkb {
              layout "${config.system.keyboard.kb_layout}";
              options "${elemAt config.system.keyboard.kb_options 0}";
            }
          }
          trackpoint {
            scroll-method "no-scroll";
          }
          touchpad {
            accel-profile "flat";
            accel-speed 0.3;
            dwt;
            dwtp;
          }
        }

        workspace "scratch"
        workspace "work"
        workspace "web"
        workspace "chat"

        cursor {
            xcursor-theme "phinger-cursors-light"
            xcursor-size 24
        }

        output "eDP-1" {
            // off
            // Native default; switch resolution at runtime with Mod+Shift+R.
            mode "2560x1600@165.02"
            scale 1.25
            // Pinned: niri auto-places outputs without an explicit position to
            // the right of the placed ones, so an unpinned panel always ends up
            // right of whatever Mod+Shift+C positions (left == right).
            position x=0 y=0
            focus-at-startup
        }

        ${strings.concatMapStringsSep "\n" (o: ''output "${o}" { off; }'') externalOutputs}

        gestures {
            hot-corners {
                off
            }
        }

        binds {
          ${toNiriBinds config.system.keyboard.bindings}

          Mod+S repeat=false { screenshot; }
          Mod+Shift+S repeat=false { screenshot-screen; }
          Mod+Ctrl+S repeat=false { screenshot-window; }

          Mod+Ctrl+R repeat=false { spawn "${resizeWindow}"; }
          Mod+Shift+R repeat=false { spawn "${resizeOutput}"; }
          Mod+Shift+C repeat=false { spawn "${connectOutput}"; }

          Mod+O repeat=false { toggle-overview; }
          Mod+Shift+Q repeat=false { close-window; }
          Mod+Shift+F { fullscreen-window; }
          Mod+Shift+Space { toggle-window-floating; }
          Mod+Shift+W { toggle-column-tabbed-display; }
          Mod+Shift+M { quit; }
          Mod+Shift+P { power-off-monitors; }

          Mod+1 { focus-workspace "scratch"; }
          Mod+2 { focus-workspace "work"; }
          Mod+3 { focus-workspace "web"; }
          Mod+4 { focus-workspace "chat"; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+0 { spawn "${externalWorkspace}" "focus-workspace"; }
          Mod+Shift+1 { move-column-to-workspace "scratch"; }
          Mod+Shift+2 { move-column-to-workspace "work"; }
          Mod+Shift+3 { move-column-to-workspace "web"; }
          Mod+Shift+4 { move-column-to-workspace "chat"; }
          Mod+Shift+5 { move-column-to-workspace 5; }
          Mod+Shift+6 { move-column-to-workspace 6; }
          Mod+Shift+7 { move-column-to-workspace 7; }
          Mod+Shift+8 { move-column-to-workspace 8; }
          Mod+Shift+0 { spawn "${externalWorkspace}" "move-column-to-workspace"; }

          Mod+Left  { focus-column-left; }
          Mod+Down  { focus-window-down; }
          Mod+Up    { focus-window-up; }
          Mod+Right { focus-column-right; }
          Mod+H     { focus-column-left; }
          Mod+J     { focus-window-down; }
          Mod+K     { focus-window-up; }
          Mod+L     { focus-column-right; }

          Mod+Shift+Left  { move-column-left; }
          Mod+Shift+Down  { move-window-down; }
          Mod+Shift+Up    { move-window-up; }
          Mod+Shift+Right { move-column-right; }
          Mod+Shift+H     { move-column-left; }
          Mod+Shift+J     { move-window-down; }
          Mod+Shift+K     { move-window-up; }
          Mod+Shift+L     { move-column-right; }

          Mod+Ctrl+H { set-column-width "-10%"; }
          Mod+Ctrl+L { set-column-width "+10%"; }
          Mod+Ctrl+J { set-window-height "-10%"; }
          Mod+Ctrl+K { set-window-height "+10%"; }

          Mod+Shift+WheelScrollDown { focus-workspace-down; }
          Mod+Shift+WheelScrollUp   { focus-workspace-up; }
          Mod+WheelScrollDown       { focus-column-right; }
          Mod+WheelScrollUp         { focus-column-left; }

          Mod+Ctrl+F { expand-column-to-available-width; }
          Mod+Ctrl+C { center-column; }
          Mod+Ctrl+V { center-visible-columns; }

          XF86AudioRaiseVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
          XF86AudioLowerVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
          XF86AudioMute         allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
          XF86AudioMicMute      allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
          XF86MonBrightnessUp   allow-when-locked=true { spawn "${brightnessctl}" "--class=backlight" "set" "+10%"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "${brightnessctl}" "--class=backlight" "set" "10%-"; }
          XF86AudioNext         allow-when-locked=true { spawn "${playerctl}" "next"; }
          XF86AudioPause        allow-when-locked=true { spawn "${playerctl}" "play-pause"; }
          XF86AudioPlay         allow-when-locked=true { spawn "${playerctl}" "play-pause"; }
          XF86AudioPrev         allow-when-locked=true { spawn "${playerctl}" "previous"; }

          Mod+BracketRight { spawn "${wpaperctl}" "next"; }
          Mod+BracketLeft  { spawn "${wpaperctl}" "previous"; }
        }
      '';
    };
  };
}
