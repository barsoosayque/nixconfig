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

  cfg = config.modules.programs.yt-dlp;

  yt-dlp-wrapped = pkgs.writeShellApplication {
    name = "yt-dlp";
    text = ''
      exec ${pkgs.yt-dlp}/bin/yt-dlp --cookies-from-browser firefox "$@"
    '';
  };

  playlistScript = pkgs.writeShellApplication {
    name = "yt-dlp-playlist";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.ffmpeg
      pkgs.dialog
      pkgs.ncurses
    ];
    text = ''
      if [ "$#" -lt 1 ]; then
        echo "Usage: yt-dlp-playlist <playlist-url> [output-dir]" >&2
        exit 1
      fi

      url="$1"
      outdir="''${2:-}"
      if [ -z "$outdir" ]; then
        outdir="${cfg.downloadsDir}"
      fi
      mkdir -p "$outdir"

      scratch="$(mktemp --suffix=.yt-dlp-playlist)"
      failures="$(mktemp)"
      trap 'rm -f "$scratch" "$failures"' EXIT

      echo "Fetching playlist entries..." >&2
      {
        echo "# yt-dlp playlist selection"
        echo "# Delete the lines for items you do NOT want to download, then save & quit."
        echo "# Lines starting with '#' and blank lines are ignored."
        echo "#"
        ${yt-dlp-wrapped}/bin/yt-dlp \
          --flat-playlist \
          --print "%(playlist_index)s	%(title)s" \
          "$url"
      } > "$scratch"

      if ! grep -qvE '^[[:space:]]*(#|$)' "$scratch"; then
        echo "Playlist appears to be empty." >&2
        exit 1
      fi

      "''${EDITOR:-vi}" "$scratch"

      mapfile -t kept < <(grep -vE '^[[:space:]]*(#|$)' "$scratch")
      if [ "''${#kept[@]}" -eq 0 ]; then
        echo "Nothing selected, aborting." >&2
        exit 0
      fi

      echo "Video quality (applies to the whole playlist):"
      select vq in "Best" "2160p" "1440p" "1080p" "720p" "480p"; do
        case "$vq" in
          "Best") vfmt="bestvideo"; break ;;
          "2160p") vfmt="bestvideo[height<=2160]"; break ;;
          "1440p") vfmt="bestvideo[height<=1440]"; break ;;
          "1080p") vfmt="bestvideo[height<=1080]"; break ;;
          "720p") vfmt="bestvideo[height<=720]"; break ;;
          "480p") vfmt="bestvideo[height<=480]"; break ;;
          *) echo "invalid choice" ;;
        esac
      done

      echo "Audio quality (applies to the whole playlist):"
      select aq in "Best" "192k" "128k" "96k"; do
        case "$aq" in
          "Best") afmt="bestaudio"; break ;;
          "192k") afmt="bestaudio[abr<=192]"; break ;;
          "128k") afmt="bestaudio[abr<=128]"; break ;;
          "96k") afmt="bestaudio[abr<=96]"; break ;;
          *) echo "invalid choice" ;;
        esac
      done

      # Subtitle language filter. Values are yt-dlp --sub-langs expressions:
      # comma-separated codes/regexes, "-" prefix excludes, "all" for everything.
      echo "Subtitles to embed (applies to the whole playlist):"
      select sl in "Default (${cfg.subLangs})" "All" "English" "Russian" "None" "Custom..."; do
        case "$sl" in
          "Default"*) sublangs="${cfg.subLangs}"; break ;;
          "All") sublangs="all,-live_chat"; break ;;
          "English") sublangs="en.*"; break ;;
          "Russian") sublangs="ru.*"; break ;;
          "None") sublangs=""; break ;;
          "Custom...")
            read -rp "Enter --sub-langs value (e.g. en.*,ja,-live_chat): " sublangs
            break
            ;;
          *) echo "invalid choice" ;;
        esac
      done

      # Embed subtitles into the mkv and drop the sidecar files afterwards
      # (--compat-options no-keep-subs), so each item ends up as a single file.
      sub_args=()
      if [ -n "$sublangs" ]; then
        sub_args=(
          --write-subs --write-auto-subs --sub-langs "$sublangs"
          --embed-subs --compat-options no-keep-subs
        )
      fi

      # --- rendering is done by dialog(1) ---------------------------------
      # dialog's --gauge widget draws the progress bar and a live-updating
      # text box; the script only feeds it data over its stdin "XXX" protocol
      # (a percent line followed by prompt lines). The bar is the global queue
      # progress, advancing in real time with each item's own download %, and
      # the box shows the current item plus yt-dlp's last N output lines.
      TAIL=20
      TOTAL="''${#kept[@]}"

      size="$(stty size 2>/dev/null || true)"
      ROWS="''${size% *}"
      COLS="''${size#* }"
      [ "$ROWS" -ge 10 ] 2>/dev/null || ROWS=24
      [ "$COLS" -ge 40 ] 2>/dev/null || COLS=80
      BOX_W=$(( COLS - 6 ))
      max_tail=$(( ROWS - 9 ))
      [ "$max_tail" -lt 1 ] && max_tail=1
      [ "$TAIL" -gt "$max_tail" ] && TAIL="$max_tail"
      BOX_H=$(( TAIL + 7 ))
      LINE_W=$(( BOX_W - 4 ))

      overall=0
      cur_n=0
      cur_title=""
      ring=()

      # Emit a single dialog "XXX" gauge update: percent + prompt text.
      emit() {
        printf 'XXX\n%d\nItem %d/%d: %.*s\n\n' \
          "$overall" "$cur_n" "$TOTAL" "$LINE_W" "$cur_title"
        local l
        for l in "''${ring[@]}"; do
          printf '%.*s\n' "$LINE_W" "$l"
        done
        printf 'XXX\n'
      }

      run_queue() {
        local completed=0 idx title line frac status floor local_o
        for entry in "''${kept[@]}"; do
          idx="''${entry%%$'\t'*}"
          title="''${entry#*$'\t'}"
          cur_n=$(( completed + 1 ))
          cur_title="$title"
          ring=()
          emit

          set +e
          ${yt-dlp-wrapped}/bin/yt-dlp \
            --newline \
            --yes-playlist \
            --playlist-items "$idx" \
            -f "$vfmt+$afmt/best" \
            --remux-video mkv \
            "''${sub_args[@]}" \
            --embed-metadata --embed-thumbnail --embed-chapters \
            -o "$outdir/%(playlist_title,playlist)s/%(playlist_index)03d - %(title)s.%(ext)s" \
            "$url" 2>&1 | {
              while IFS= read -r line; do
                line="''${line//$'\r'/}"
                ring+=("$line")
                if [ "''${#ring[@]}" -gt "$TAIL" ]; then
                  ring=("''${ring[@]:1}")
                fi
                if [[ "$line" =~ ([0-9]+)(\.[0-9]+)?%[[:space:]] ]]; then
                  frac="''${BASH_REMATCH[1]}"
                  local_o=$(( (completed * 100 + frac) / TOTAL ))
                  [ "$local_o" -gt "$overall" ] && overall="$local_o"
                fi
                emit
              done
            }
          status="''${PIPESTATUS[0]}"
          set -e

          completed=$(( completed + 1 ))
          floor=$(( completed * 100 / TOTAL ))
          [ "$floor" -gt "$overall" ] && overall="$floor"
          [ "$status" -ne 0 ] && printf '%s\n' "$idx - $title" >> "$failures"
        done

        overall=100
        cur_n="$TOTAL"
        cur_title="done"
        ring=()
        emit
      }

      run_queue | dialog \
        --backtitle "yt-dlp playlist" \
        --title "Downloading to $outdir" \
        --gauge "Starting..." "$BOX_H" "$BOX_W" 0

      clear
      printf 'Finished: %d/%d items.\n' "$TOTAL" "$TOTAL"
      if [ -s "$failures" ]; then
        printf 'Failed items:\n'
        while IFS= read -r f; do printf '  - %s\n' "$f"; done < "$failures"
        exit 1
      fi
    '';
  };
in
{
  options.modules.programs.yt-dlp = {
    enable = mkEnableOption "yt-dlp";

    downloadsDir = mkOption {
      type = with types; str;
      default = config.system.user.dirs.videos.absolutePath;
      description = "Default directory yt-dlp-playlist saves playlists into, when none is given on the command line";
    };

    subLangs = mkOption {
      type = with types; str;
      default = "en.*,ru.*";
      description = "Default value offered for the yt-dlp-playlist subtitle language filter (a yt-dlp --sub-langs expression)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      yt-dlp-wrapped
      playlistScript
    ];
  };
}
