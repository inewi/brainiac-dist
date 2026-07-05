# Copilot CLI Tool Mapping

brainiac skills/commands use Claude Code tool names. In GitHub Copilot CLI, use the equivalent:

| Claude Code | Copilot CLI |
|---|---|
| Read | view |
| Write | create |
| Edit | edit |
| Bash | bash |
| Grep | grep |
| Glob | glob |
| Skill | skill |
| Task (subagent) | agent |
| WebFetch | web_fetch |

Run the brainiac CLI as `npx --no-install brainiac <verb>`. On a `curl | sh` dev box the
prebuilt binary is on `PATH`, so bare `brainiac <verb>` also works — the `npx --no-install`
form is the portable one that never downloads a wrong package.
brainiac's slash-commands (`/brainiac:*`) do not exist in Copilot — use the `brainiac-ship`,
`brainiac-develop`, and `brainiac` agents instead.
