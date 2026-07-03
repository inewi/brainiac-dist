---
description: Detect dangling cross-repo edges + inject missing contract-consumer dependencies — read-only by default, auto-fix with --auto-edge
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:sequencer

Validate cross-repo task graphs and enforce the contract-before-consumer
invariant. The sequencer detects two classes of problems:

1. **Dangling edges** — `[repo:name]` annotations pointing at unknown repos,
   or `depends_on` references to task IDs that don't exist in any provisioned repo.
2. **Missing contract edges** — tasks that reference `[repo:target]` but don't
   declare a dependency on the target repo's contract-publishing tasks.

## 1. Detect dangling edges

```bash
brainiac sequencer --spec <spec-dir>
```

Scans the task graph for unresolvable cross-repo references. Exit code is
non-zero when dangling edges are found.

For multiple repos, use `--repos` with comma-separated paths to tasks.md files:

```bash
brainiac sequencer --repos "/path/to/web/tasks.md,/path/to/billing/tasks.md"
```

## 2. Scan and inject contract edges

Add `--auto-edge` to scan for AND inject missing contract-consumer dependencies:

```bash
brainiac sequencer --repos "web/tasks.md,billing/tasks.md" --auto-edge
```

With `--auto-edge`, the sequencer writes the modified `tasks.md` back to disk
immediately. Pass `--dry-run` alongside `--auto-edge` to preview without writing.

The sequencer identifies contract-publishing tasks by keywords in the task text:
`export`, `expose`, `publish`, `api`, `endpoint`, `contract`, `interface`,
`schema`, `openapi`, `grpc`, `proto`, `route`, `handler`, `provider`.

## 3. Preview mode

Add `--dry-run` to preview what would be injected without writing:

```bash
brainiac sequencer --repos "web/tasks.md,billing/tasks.md" --auto-edge --dry-run
```
