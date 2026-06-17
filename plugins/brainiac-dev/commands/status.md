---
description: Show all tasks across repos — completed, in progress, blocked. Reads status.json from each reference repo to give a cross-repo view of the current state. Use to understand overall progress.
allowed-tools: Bash, Read, Glob, Grep
---

# Cross-Repo Status

$ARGUMENTS

Read `status.json` from the current repo and any referenced repos to build a
cross-repo task dashboard.

## Step 1: Read current repo status

Read `.brainiac/status.json` in the current repo. Parse tasks, their completion
state, and timestamps.

## Step 2: Find cross-repo references

Check `tasks.md` (or the active spec's tasks.md) for `[repo:name]` annotations.
For each referenced repo, check if `.references/<name>/.brainiac/status.json`
exists and read it. If the file is missing, report the repo as "not grounded —
run `brainiac ground` first." Do not error — just note the gap and continue.

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
