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

Run the brainiac CLI as `npx --no-install brainiac <verb>` (it is not a global binary).
brainiac's slash-commands (`/brainiac:*`) do not exist in Copilot — use the `brainiac-ship`,
`brainiac-develop`, and `brainiac` agents instead.
