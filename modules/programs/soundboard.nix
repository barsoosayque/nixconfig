{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.modules.programs.soundboard;

  fxSinkName = "soundboard";
  micSinkName = "soundboard-mic";
  sourceName = "soundboard-mic-input";

  playSound = pkgs.writeShellScript "soundboard-play" ''
    dir="${cfg.soundsDir}"
    mkdir -p "$dir"

    shopt -s nullglob
    files=("$dir"/*)
    if [ ''${#files[@]} -eq 0 ]; then
      exit 0
    fi

    choice="$(printf '%s\n' "''${files[@]##*/}" | sort | ${pkgs.tofi}/bin/tofi ${config.modules.programs.tofi.args} --prompt-text '  Sound: ')"
    [ -z "$choice" ] && exit 0

    exec ${pkgs.pipewire}/bin/pw-play --target ${fxSinkName} "$dir/$choice"
  '';

  stopSound = pkgs.writeShellScript "soundboard-stop" ''
    ${pkgs.procps}/bin/pkill -f "^${pkgs.pipewire}/bin/pw-play --target ${fxSinkName} " || true
  '';
in
{
  options.modules.programs.soundboard = {
    enable = mkEnableOption "soundboard";

    soundsDir = mkOption {
      type = with types; str;
      default = "${config.system.user.home}/.config/soundbar";
      description = "Directory scanned for playable sound files";
    };
  };

  config = mkIf cfg.enable {
    # "soundboard" is a plain FX sink that pw-play targets; its monitor is
    # mirrored both to the default output (so you hear it, and its volume
    # slider controls that) and into "soundboard-mic", which also has the
    # real mic looped in, for a single mixed feed. That monitor is remapped
    # into a plain (non-Monitor-class) source, since Chromium apps like
    # Discord filter monitor sources out of their input-device list; select
    # "Soundboard-Mic-Input" there instead.
    services.pipewire.extraConfig.pipewire-pulse."10-soundboard" = {
      "pulse.cmd" = [
        {
          cmd = "load-module";
          args = "module-null-sink sink_name=${fxSinkName} sink_properties=device.description=Soundboard";
        }
        {
          cmd = "load-module";
          args = "module-null-sink sink_name=${micSinkName} sink_properties=device.description=Soundboard-Mic";
        }
        {
          cmd = "load-module";
          args = "module-loopback source=@DEFAULT_SOURCE@ sink=${micSinkName} source_dont_move=false sink_dont_move=true";
        }
        {
          cmd = "load-module";
          args = "module-loopback source=${fxSinkName}.monitor sink=${micSinkName} source_dont_move=true sink_dont_move=true";
        }
        {
          cmd = "load-module";
          args = "module-loopback source=${fxSinkName}.monitor sink=@DEFAULT_SINK@ source_dont_move=true sink_dont_move=false";
        }
        {
          cmd = "load-module";
          args = "module-remap-source master=${micSinkName}.monitor source_name=${sourceName} source_properties=device.description=Soundboard-Mic-Input";
        }
      ];
    };

    system.keyboard.bindings."super + b" = playSound;
    system.keyboard.bindings."super + shift + b" = stopSound;
  };
}
