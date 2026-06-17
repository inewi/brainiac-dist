---
description: Validate the cross-repo task graph — delegates to the brainiac plan engine for parse/validate/phase of epics/EPIC-####/tasks.md
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:tasks

Validate the cross-repo task plan for an epic. Tasks use the same grammar as
per-repo `tasks.md`: `T-###`, `depends_on`, `[P]`, `[repo]`. This command
delegates to the existing `brainiac plan --spec` engine.

**Status truth:** the epic-level `tasks.md` stores the cross-repo **plan**
(which tasks, which repo, ordering). Actual task **status** is derived from
per-repo checkboxes — never stored here.

## 1. Validate the task graph

```bash
brainiac plan --spec epics/EPIC-####-slug/tasks.md
```

The plan engine parses the task list, validates the DAG, and prints
foundations-first phases.

## 2. Act on the output

On success, the phases tell you the execution order. On violations, fix the
graph and re-run. Cross-repo edges (`[repo:name]`) are flagged for the
sequencer.
