# brainiac-dist

Public distribution for **brainiac** — install the developer surface with **no private-repo access**.

> Generated from `inewi/brainiac-pipeline` by `npm run build:dev-plugin`. Do not edit by hand.

## Install (CLI + plugin, one command)

```sh
curl -fsSL https://raw.githubusercontent.com/inewi/brainiac-dist/main/install.sh | sh
```

Installs the prebuilt `brainiac` CLI for your platform (macOS/Linux) into `~/.local/bin`, then —
if a Claude Code or Copilot CLI is present — runs `brainiac setup --dev` to wire the dev plugin +
superpowers. No inewi access required. Pass `-s -- --no-setup` to install the CLI only.

## Install the plugin only

Claude Code:

```sh
claude plugin marketplace add inewi/brainiac-dist
claude plugin install brainiac-dev@inewi
```

GitHub Copilot CLI: replace `claude` with `copilot`.

This installs the brainiac **develop** pipeline (`/brainiac:develop`, `debug`, `quick`) plus the
shared governance gates and conventions — no inewi access required. PM/ship surfaces stay private.
