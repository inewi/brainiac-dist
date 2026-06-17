---
description: Validate + foundations-first phase a spec's tasks.md graph the ONE WAY — a read-only gate that rejects malformed tasks, unknown/self deps, duplicates, and cycles.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:plan

Turn an authored spec's `tasks.md` checklist into a validated, layered task
graph. brainiac specs live the ONE WAY, in `‹repo›/specs/EPIC-####-slug/`; this
command reads only that home. It NEVER reads, adapts to, or migrates a repo's
legacy spec dirs. This is a GATE: a broken graph fails loudly and must be fixed
before handoff.

**Argument:** the spec directory, e.g. `specs/EPIC-0007-add-export` (a path to
the dir, or directly to its `tasks.md`).

## 1. Run the gate

```bash
brainiac plan --spec "specs/EPIC-####-slug"
```

The engine parses every `- [ ] T-###: …` task line — its `depends_on`, `[P]`
parallel marker, and optional `[repo:name]` cross-repo tag — then validates the
graph and layers it foundations-first.

## 2. Act on the output

On success it prints each `Phase N: T-…, T-…` (foundations in Phase 0, then
their dependents), any `cross-repo:` edges, and `plan: OK (N task(s), M
phase(s))`, exiting 0. The phases are the execution order: Phase 0 first, each
later phase only after its predecessors are done.

On failure it lists each `plan: [<kind>] <detail>` and exits 1. Fix the cause in
`tasks.md`, then re-run until it returns 0:

- `malformed-task` — a `- [ ]`/`- [x]` line that is not a `T-###:` task. Rewrite
  it as a tracked task or drop the stray checkbox; never leave untracked tasks.
- `unknown-dependency` — a `depends_on:` cites an id that does not exist. Fix the
  id (or add the missing task).
- `self-dependency` — a task depends on itself. Remove it from its own
  `depends_on`.
- `duplicate-id` — two tasks share a `T-###`. Renumber one.
- `cycle` — the `depends_on` edges form a loop. Break it so the graph is a DAG.
- `no-tasks` — `tasks.md` declares no `T-###` tasks. Author the checklist first
  (via `/brainiac:specify`).

`brainiac plan` is READ-ONLY — it writes nothing. Only report the plan as green
once the gate exits 0 and the phases reflect the intended execution order.
