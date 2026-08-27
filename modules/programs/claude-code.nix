{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  inherit (builtins) toJSON;

  cfg = config.modules.programs.claude-code;
in
{
  options.modules.programs.claude-code = {
    enable = mkEnableOption "claude code";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.claude-code ];

    environment.variables = {
      CLAUDE_CONFIG_DIR = "${config.system.user.dirs.config.absolutePath}/claude";
    };

    system.user.hm.xdg.configFile."claude/settings.json".text = toJSON {
      theme = "dark-ansi";
      permissions = {
        allow = [
          "Bash(find *)"
          "Bash(grep *)"
          "Bash(ls *)"
          "Bash(echo *)"
          # xargs always runs a command by design; only allow it paired with echo
          # so it can be used to preview arguments, not to execute anything else
          "Bash(xargs echo *)"
          "WebSearch"

          # git subcommands that are always read-only, any flags/args
          "Bash(git status:*)"
          "Bash(git log:*)"
          "Bash(git diff:*)"
          "Bash(git show:*)"
          "Bash(git blame:*)"
          "Bash(git describe:*)"
          "Bash(git shortlog:*)"
          "Bash(git rev-parse:*)"
          "Bash(git ls-files:*)"
          "Bash(git ls-tree:*)"
          "Bash(git ls-remote:*)"
          "Bash(git cat-file:*)"
          "Bash(git reflog show:*)"
          "Bash(git stash list:*)"
          "Bash(git stash show:*)"
          "Bash(git remote show:*)"

          # subcommands that are only read-only in these specific forms;
          # other forms (branch -d, stash pop/drop, tag <name>, remote add,
          # config <key> <value>, ...) are mutating and stay unlisted
          "Bash(git branch)"
          "Bash(git branch -a)"
          "Bash(git branch -v)"
          "Bash(git branch -r)"
          "Bash(git branch --list)"
          "Bash(git remote)"
          "Bash(git remote -v)"
          "Bash(git tag)"
          "Bash(git config -l)"
          "Bash(git config --list)"
          "Bash(git config --get:*)"
        ];
        ask = [
          # never silently allow file removal, even if a broader rule would otherwise match
          "Bash(rm *)"
          "Bash(find * -delete*)"
        ];
        deny = [
          # find can execute arbitrary commands via these flags; keep it read-only
          "Bash(find * -exec *)"
          "Bash(find * -exec)"
          "Bash(find * -execdir *)"
          "Bash(find * -execdir)"
          "Bash(find * -ok *)"
          "Bash(find * -ok)"
          "Bash(find * -okdir *)"
          "Bash(find * -okdir)"
          # no privilege escalation, full stop
          "Bash(sudo *)"
          "Bash(sudoedit *)"
        ];
      };
      hooks = {
        Stop = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${
                  config.modules.services.dunst.notify {
                    title = "Claude Code";
                    msg = "Task Completed";
                    icon = "claude-line";
                  }
                }";
              }
            ];
          }
        ];
        Notification = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${
                  config.modules.services.dunst.notify {
                    title = "Claude Code";
                    msg = "Input Required";
                    icon = "claude-line";
                  }
                }";
              }
            ];
          }
        ];
      };
    };
  };
}
