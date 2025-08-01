{ config, options, pkgs, lib, ... }:

let
  inherit (lib) mkOption types;
  inherit (lib.lists) foldl;
  inherit (lib.strings) concatMapStringsSep;
  inherit (pkgs) writeScript;
  inherit (builtins) listToAttrs concatStringsSep hashString;

  mkEventOption = eventDef:
    {
      "${eventDef.name}" = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = "User defined commands to run on event: ${eventDef.description}";
      };

      "${eventDef.name}Callbacks" = {
        beforeCommands = mkOption {
          type = with types; listOf path;
          default = [ ];
          description = ''
            Script to run before any user command for this event.
            Avaliable variables: EVENT_DESCRIPTION.
          '';
        };

        update = mkOption {
          type = with types; listOf path;
          default = [ ];
          description = ''
            Script to run when one of the user commands is finished (run for every command)".
            Available variables: EVENT_DESCRIPTION, CMD_EXITCODE, CMD_STDOUT, CMD_STDERR.
          '';
        };

        afterCommands = mkOption {
          type = with types; listOf path;
          default = [ ];
          description = ''
            Script to run after all user commands are finished
            Avaliable variables: EVENT_DESCRIPTION.
          '';
        };
      };

      "${eventDef.name}Script" = mkOption {
        type = with types; path;
        description = "Path to a script to fire a ${eventDef.name} event";
        readOnly = true;
      };
    };

  mkEvents = eventDefs:
    foldl (acc: val: acc // val) { }
      (map mkEventOption eventDefs);

  mkRunScript = eventDef:
    let
      runCallbacks = cmd:
        concatStringsSep "\n" config.system.events."${eventDef.name}Callbacks"."${cmd}";

      runUserCmds = cmds:
        let
          coroutine = cmd:
            writeScript "events-${eventDef.name}-coroutine-${hashString "sha1" cmd}"
              ''
                #!${pkgs.dash}/bin/dash
                ${cmd}
                ${runCallbacks "update"}
              '';
        in
        concatMapStringsSep "\n" coroutine cmds;

    in
    writeScript "events-${eventDef.name}-run" ''
      #!${pkgs.dash}/bin/dash

      export EVENT_DESCRIPTION="${eventDef.description}"

      ${runCallbacks "beforeCommands"}
      ${runUserCmds config.system.events."${eventDef.name}"}
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
    { name = "onWMLoaded"; description = "WL is loaded"; }
    { name = "onTorrentDone"; description = "Transmission torrent downloaded"; }
    { name = "onScreenshot"; description = "Screenshot made"; }
  ];
in
{
  options = {
    helpers = {
      mkAllEventsCallback = mkOption {
        type = with types; functionTo (functionTo attrs);
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
