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
          Avaliable variables: EVENT_DESCRIPTION.
          '';
        };

        update = mkOption {
          type = types.listOf types.path;
          default = [];
          description = ''
          Script to run when one of the user commands is finished (run for every command)".
          Available variables: EVENT_DESCRIPTION, CMD_EXITCODE, CMD_STDOUT, CMD_STDERR.
          '';
        };

        afterCommands = mkOption {
          type = types.listOf types.path;
          default = [];
          description = ''
          Script to run after all user commands are finished
          Avaliable variables: EVENT_DESCRIPTION.
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

  mkRunScript = eventDef:
    let
      asyncRun = "${pkgs.async}/bin/async -s=$ASYNC_SOCKET";

      runCallbacks = cmd:
        concatStringsSep "\n" config.system.events."${eventDef.name}Callbacks"."${cmd}";

      runUserCmds = cmds:
        let
          coroutine = cmd:
            writeScript "events-${eventDef.name}-coroutine-${hashString "sha1" cmd}"
            ''
              #!${pkgs.dash}/bin/dash
              export CMD_EXITCODE=$(${cmd})
              ${runCallbacks "update"}
            '';

          sh = cmd:
            ''
              export CMD_STDOUT="$TMP/stdout"
              export CMD_STDERR="$TMP/stderr"
              ${asyncRun} cmd -o $CMD_STDOUT -e $CMD_STDERR -- ${coroutine cmd}
            '';
        in concatMapStringsSep "\n" sh cmds;

    in
    writeScript "events-${eventDef.name}-run" ''
      #!${pkgs.dash}/bin/dash

      export TMP=$(mktemp -d)
      export ASYNC_SOCKET="$TMP/socket"
      export EVENT_DESCRIPTION="${eventDef.description}"

      ${runCallbacks "beforeCommands"}
      ${asyncRun} server --start
      ${runUserCmds config.system.events."${eventDef.name}"}
      ${asyncRun} wait
      ${asyncRun} server --stop
      ${runCallbacks "afterCommands"}
    '';

  mkRunScripts = eventDefs:
    listToAttrs
    (map (def: { name = "${def.name}Script"; value = mkRunScript def; }) eventDefs);
in
let
  commands = [
    { name = "onStartup"; description = "User system startup"; }
    { name = "onReload"; description = "User System reload"; }
    { name = "onTorrentDone"; description = "Transmission torrent downloaded"; }
    { name = "onScreenshot"; description = "Screenshot made"; }
  ];
in
{
  options = {
    helpers = {
      mkAllEventsCallback = mkOption {
        type = types.functionTo (types.functionTo types.attrs);
        readOnly = true;
        description = ''
          Helper function to make all events callback in modules.
          Usage:
          inherit (config.helpers) mkAllEventsCallback;
          system.events = mkAllEventsCallback "afterCommands" script;
        '';
      }; 
    };

    system.events = mkEvents commands;
  };

  config = {
    helpers.mkAllEventsCallback = callbackName: script:
      listToAttrs (map (def: { name = "${def.name}Callbacks"; value = { "${callbackName}" = [ script ]; }; }) commands);

    system.events = mkRunScripts commands;
  };
}
