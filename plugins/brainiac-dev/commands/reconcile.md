---
description: Read-only drift differ — recompute live status from on-disk tasks.md checkboxes (repo checkbox wins) and diff it against the published .brainiac/status.json. Never writes.
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

The engine builds the live status from on-disk checkboxes (repo checkbox wins),
reads the published `.brainiac/status.json`, and diffs the two — ignoring the
`generated_at` timestamp.

## 2. Act on the output

When in sync it prints `reconcile: in sync (done/total tasks done)` and exits 0.

When drift exists it lists each `reconcile: [<kind>] <detail>` and exits 1.
reconcile writes NOTHING; to clear the drift, re-publish via
`/brainiac:handoff` (which writes the fresh `status.json`) — never hand-edit the
manifest. Drift kinds:

- `no-published-status` — no `.brainiac/status.json` (or it is malformed). The
  repo was never handed off; run `/brainiac:handoff` to publish.
- `rollup-changed` — the task done/total advanced since publish (checkboxes
  moved). Re-publish to record the progress.
- `epic-added` / `epic-removed` — an `EPIC-####` home appeared or vanished
  versus the published manifest.
- `backref-changed` — an epic's spec back-reference moved.
- `convention-version-changed` / `head-moved` — the brainiac convention version
  or repo HEAD advanced since publish.

reconcile is a read-only audit: report it green only when it exits 0.
