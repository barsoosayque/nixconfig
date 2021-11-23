{ config, options, pkgs, pkgsLocal, lib, ... }:

with lib;
let
  inherit (pkgs) writeScript;
  inherit (builtins) hashString;

  mkEventOption = eventDef:
    {
      "${eventDef.name}" = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "User defined commands to run on event: ${eventDef.description}";
      };

      "${eventDef.name}Callbacks" = {
        beforeCommands = mkOption {
          type = types.listOf types.path;
          default = [];
          description = ''
          Script to run before any user command for this event.
          '';
        };

        update = mkOption {
          type = types.listOf types.path;
          default = [];
          description = ''
          Script to run when one of the user commands is finished (run for every command)".
          Available variables: CMD_EXITCODE, CMD_STDOUT, CMD_STDERR.
          '';
        };

        afterCommands = mkOption {
          type = types.listOf types.path;
          default = [];
          description = ''
          Script to run after all user commands are finished
          '';
        };
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
      asyncRun = "${pkgs.async}/bin/async -s=$ASYNC_SOCKET";

      runCallbacks = cmd:
        concatStringsSep "\n" config.system.events."${event}Callbacks"."${cmd}";

      runUserCmds = cmds:
        let
          coroutine = cmd:
            writeScript "events-${event}-coroutine-${hashString "sha1" cmd}"
            ''
              #!${pkgs.dash}/bin/dash
              export CMD_EXITCODE=$(exec "${cmd}")
              ${runCallbacks "update"}
            '';

          executable = cmd:
            writeScript "events-${event}-executable-${hashString "sha1" cmd}"
            ''
              #!${pkgs.dash}/bin/dash
              export CMD_STDOUT=$(mktemp)
              export CMD_STDERR=$(mktemp)
              ${asyncRun} cmd -o $CMD_STDOUT -e $CMD_STDERR -- ${coroutine cmd}
            '';
        in concatMapStringsSep "\n" executable cmds;

    in
    writeScript "events-${event}-run" ''
      #!${pkgs.dash}/bin/dash

      export ASYNC_SOCKET=$(mktemp)

      ${runCallbacks "beforeCommands"}

      ${asyncRun} --start
      ${runUserCmds config.system.events."${event}"}
      ${asyncRun} wait
      ${asyncRun} server --stop

      ${runCallbacks "afterCommands"}
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
  options.system.events = mkEvents commands;
  config.system.events = mkRunScripts commands;
}
