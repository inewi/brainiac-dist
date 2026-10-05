---
description: Show all tasks across repos — completed, in progress, blocked. Reads each repo's tasks.md checkboxes (the status itself) to give a cross-repo view of the current state. Use to understand overall progress.
allowed-tools: Bash, Read, Glob, Grep
---

# Cross-Repo Status

$ARGUMENTS

Read the `tasks.md` checkboxes of the current repo and any referenced repos to
build a cross-repo task dashboard — the checkboxes ARE the status (`status.json`
carries no copy of them). From a brain root, `brainiac status` prints the same
counts for every reference repo and in-flight epic.

## Step 1: Read current repo status

Read each `specs/EPIC-*/tasks.md` in the current repo. Parse the tasks and their
checkbox state (`- [x]` done, `- [ ]` open).

## Step 2: Find cross-repo references

Check `tasks.md` (or the active spec's tasks.md) for `[repo:name]` annotations.
For each referenced repo, read the `specs/EPIC-*/tasks.md` checkboxes under
`.references/<name>/`. If the clone is missing, report the repo as "not cloned —
run `brainiac references` first." Do not error — just note the gap and continue.

## Step 3: Report

```text
Cross-repo status:

  billing (this repo):
    ◻ T-004: API RODO — in progress (started 2h ago)
    ◻ T-005: Dziennik audytu — available
    ✓ T-001, T-002, T-003

  api:
    ✓ T-003: Kontrakt API — completed (2026-06-06)

  web:
    ◻ T-012: Employee document upload API — available
```

## Step 4: Highlight blockers

For any blocked task, show what's blocking it and which repo owns the blocker:

```text
Blockers:
  T-006 (billing) blocked by T-012 (web) — not yet started
```

## Step 5: Suggest next action

If the developer is in a repo with available tasks, suggest `/brainiac:develop`.
If all tasks in the current repo are blocked, suggest which upstream task to
unblock first.
