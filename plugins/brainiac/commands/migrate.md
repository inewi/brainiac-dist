---
description: Roll all provisioned repos forward to the current brainiac convention version — dry-run-able, transactional, halts-and-reports
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:migrate

Roll provisioned repos forward when brainiac's schema or paths change.
brainiac is SemVer'd; each provisioned repo carries a
`brainiac_convention_version` stamp in its `.brainiac/status.json`.
This command scans the given repos, detects any that are behind the
current `CONVENTION_VERSION`, and applies migrations to bring them current.

## 1. Scan for stale repos

```bash
brainiac migrate --repos "/path/to/web,/path/to/billing"
```

Pass a comma-separated list of absolute paths to provisioned repo roots.
The command reads each repo's published `status.json` and compares its
`brainiac_convention_version` to the current version.

Use `--dry-run` to preview which repos would be migrated without writing.

## 2. Act on the output

On success, each repo is printed with its status: `up to date` or `migrated
vX → vY`. If a repo is behind but no migration exists for its version, the
command halts with a clear error. Fix the gap by defining a `Migration` in
`src/migrate/migrate.ts` and re-run.
