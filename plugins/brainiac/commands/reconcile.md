---
description: Read-only drift differ — diff the epics and spec homes on disk against the published .brainiac/status.json. Never compares task checkboxes (they are the status) and never writes.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:reconcile

Detect drift between the repo's live state and the published status manifest.
brainiac specs live the ONE WAY, in `‹repo›/specs/EPIC-####-slug/`; reconcile
recomputes status from those `tasks.md` checkboxes and compares it against the
last published `.brainiac/status.json`. It is READ-ONLY and NEVER writes — the
repo checkbox is the SSOT; reconcile only reports where the published manifest
has fallen behind.

**Argument:** none required. Optional: `--root <path>` to select the repo
(default: the current directory).

## 1. Run the differ

```bash
brainiac reconcile --root "<repo>"
```

The engine discovers the epics and their spec homes on disk, reads the published
`.brainiac/status.json`, and diffs the two — never the task checkboxes (they are
the status) and never the `generated_at`/`generated_from` stamps.

## 2. Act on the output

When in sync it prints `reconcile: <repo>: in sync` and exits 0.

When drift exists it lists each `reconcile: <repo>: [<kind>] <detail>` and exits 1.
Every line names the checkout it diffed. Run at a brain root (a tree carrying
`references.json` or `.references/`), reconcile fans out over every grounded
checkout under `.references/` instead of diffing the brain repo itself, and
never-grounded checkouts are skipped with a `never grounded — skipped` line.
reconcile writes NOTHING; to clear the drift, re-publish via
`/brainiac:handoff` (which writes the fresh `status.json`) — never hand-edit the
manifest. Drift kinds:

- `no-published-status` — no `.brainiac/status.json` (or it is malformed). The
  repo was never handed off; run `/brainiac:handoff` to publish.
- `epic-added` / `epic-removed` — an `EPIC-####` home appeared or vanished
  versus the published manifest.
- `backref-changed` — an epic's spec back-reference moved.
- `convention-version-changed` — the brainiac convention version advanced since
  publish.

Task checkboxes are never compared: they ARE the status, and `status.json`
carries no copy of them (`brainiac status` counts them live). A commit after
publish is not drift either.

reconcile is a read-only audit: report it green only when it exits 0.
