# brainiac-dist

Public distribution for **brainiac** — install the developer surface with **no private-repo access**.

> Generated from `inewi/brainiac-pipeline` by `npm run build:dev-plugin`. Do not edit by hand.

## Install the dev plugin

Claude Code:

```sh
claude plugin marketplace add inewi/brainiac-dist
claude plugin install brainiac-dev@inewi
```

GitHub Copilot CLI: replace `claude` with `copilot`.

This installs the brainiac **develop** pipeline (`/brainiac:develop`, `debug`, `quick`) plus the
shared governance gates and conventions — no inewi access required. PM/ship surfaces stay private.
