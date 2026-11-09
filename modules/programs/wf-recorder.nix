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
    ;

  cfg = config.modules.programs.wf-recorder;

  notifyStarted = config.modules.services.dunst.notify {
    title = "Recording";
    msg = "Press again to stop";
    icon = "record-circle-line";
  };

  notifySaved = config.modules.services.dunst.notify {
    title = "Recording saved";
    msg = "$RECORDING_PATH";
    icon = "video-line";
  };

  # First press: pick a region and start recording it. Second press: stop,
  # which makes wf-recorder finalize the file.
  toggleRecording = pkgs.writeShellScript "wf-recorder-toggle" ''
    if ${pkgs.procps}/bin/pkill -INT -x wf-recorder; then
      exit 0
    fi

    geom="$(${pkgs.slurp}/bin/slurp -d)" || exit 0

    # yuv420p needs even dimensions, slurp happily gives odd ones.
    read -r pos size <<< "$geom"
    w="''${size%x*}"
    h="''${size#*x}"
    geom="$pos $(( w / 2 * 2 ))x$(( h / 2 * 2 ))"

    dir="${cfg.recordingsDir}/$(date +%Y/%m)"
    mkdir -p "$dir"
    export RECORDING_PATH="$dir/Recording from $(date '+%Y-%m-%d %H-%M-%S').mp4"

    ${notifyStarted}
    ${pkgs.wf-recorder}/bin/wf-recorder -g "$geom" -x yuv420p -f "$RECORDING_PATH"
    [ -s "$RECORDING_PATH" ] && ${notifySaved}
  '';
in
{
  options.modules.programs.wf-recorder = {
    enable = mkEnableOption "wf-recorder";

    recordingsDir = mkOption {
      type = with types; str;
      default = "${config.system.user.dirs.videos.absolutePath}/recordings";
      description = "Directory to put recordings to, organized into <dir>/<year>/<month>";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wf-recorder
      pkgs.slurp
    ];

    system.keyboard.bindings = {
      "super + r" = "${toggleRecording}";
    };
  };
}
