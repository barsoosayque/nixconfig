{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScript;

  mkEventOption = eventDef:
    {
      "${eventDef.name}" = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "User defined commands to run on event: ${eventDef.description}";
      };

      "${eventDef.name}Observer" = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          POSIX script to observe lifetime of the event with special ${eventDef.name} callbacks:

          `beforeCommands()` is called before running any user command for this event.

          `update(command, exitcode, out, err)` is called when one of the command is finished.
          Argument `command` contains command that was run, `exitcode` is return status of the command,
          both `out` and `err` are captured stdout and stderr of the command.

          `afterCommands()` is called after all user commands are finished.
        '';
      };

      "${eventDef.name}Script" = mkOption {
        type = types.path;
        description = "Path to a script to fire a ${eventDef.name} event";
        readOnly = true;
      };
    };

  mkEvents = eventDefs:
    lists.foldl (acc: val: acc // val) {}    
    (map mkEventOption eventDefs);

  mkRunScript = event:
    let
      asyncBin = "${pkgs.async}/bin/async";

      mapToLines = f: list:
        concatStringsSep "\n" (map f list);

      observerCmd = cmd:
        mapToLines 
        (p: ''
          ${cmd}() {}
          source ${p}
          ${cmd} $@
          unset -f ${cmd}
        '') config.events."${event}Observer";
    in
    writeScript "events-${event}-run" ''
      #!${pkgs.dash}/bin/dash

      # Define callbacks
      beforeCommandsAll() {
        ${observerCmd "beforeCommands"}
      }
      updateAll() {
        ${observerCmd "update"}
      }
      afterCommandsAll() {
        ${observerCmd "afterCommands"}
      }

      # Setup async
      SOCKET=$(mktemp)
      alias as="${asyncBin} -s=$SOCKET"

      runCmd() {
        OUT_FILE=$(mktemp)
        ERR_FILE=$(mktemp)

        inner() {
          EXITCODE=$(exec "$1")
          OUT=$(cat $OUT_FILE)
          ERR=$(cat $ERR_FILE)

          updateAll "$1" "$EXITCODE" "$OUT" "$ERR"
        }
        
        export -f inner
        as cmd -o "$OUT_FILE" -e "$ERR_FILE" -- inner "$1"
        unset -f inner
      }

      beforeCommadsAll

      as server --start
      ${mapToLines (cmd: "runCmd \"${cmd}\"") config.events."${event}"}
      as wait
      as server --stop

      afterCommandsAll
    '';

  mkRunScripts = eventDefs:
    listToAttrs
    (map (def: { name = "${def.name}Script"; value = mkRunScript def.name; }) eventDefs);
in
let
  commands = [
    { name = "onTest"; description = "Test event"; }
    { name = "onReload"; description = "User System reload"; }
    { name = "onTorrentDone"; description = "Transmission torrent downloaded"; }
  ];
in
{
  options.events = mkEvents commands;
  config.events = mkRunScripts commands;
}
