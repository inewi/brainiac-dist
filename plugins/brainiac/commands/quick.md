---
description: Scale-adaptive escape hatch — skip research/initiative/epic/clarify/analyze for single-repo, no-contract, small diffs (TDD + verification check + symbol/secret gate are NEVER skipped)
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:quick

The escape hatch for changes that don't need the full pipeline. `:quick` skips
`research`, `initiative`, `epic`, `clarify`, `analyze`, and `reconcile` — but it
**may not** skip writing a spec stub, TDD, the spec's runnable verification check,
or the symbol/secret gate. These are the constitutional non-escapables (§7.3).

**Trigger:** single repo · no cross-repo or contract change · ≤ N files /
one-sentence diff. If the change doesn't meet these criteria, use the full
pipeline (`/brainiac:specify` → `/brainiac:clarify` → `/brainiac:plan` →
`/brainiac:analyze` → `/brainiac:reconcile` → `/brainiac:handoff`).

## 1. Verify the trigger conditions

Confirm with the operator that ALL of these hold:

- **Single repo.** The change touches exactly one repo. No cross-repo
  dependency, no contract change across repos.
- **No contract change.** The change does not modify a producer contract
  (OpenAPI spec, shared DTO, API surface, database schema) that a consumer
  repo depends on.
- **Small diff.** The change is ≤ N files and the intent can be described in
  one sentence.
- **Repo is grounded.** `brainiac check` passes and the repo has a `.brainiac/`
  steering directory.

If any condition is not met, refuse and tell the operator to use the full
pipeline.

## 2. Write the spec stub

Scaffold a minimal spec the ONE WAY. Use `brainiac specify` for the title:

```bash
brainiac specify "<one-sentence title>" --repo <repo-path>
```

The spec trio is scaffolded but the `requirements.md` and `design.md` are
minimal — just enough to satisfy the gates. Fill in:

- **requirements.md:** One EARS requirement (`FR-001: WHEN … THE SYSTEM SHALL …`).
  Include the `## Verification` heading with a runnable check (the test command).
- **design.md:** At minimum, list the affected symbols (`## Affected symbols`).
- **tasks.md:** One or two tasks. Use the standard grammar (`T-###`, `depends_on`).

## 3. TDD ALWAYS

Write the failing test first. Run it and confirm it fails (in statically-typed
repos, a compile error naming the missing symbol IS the failing test for
schema-shaped tasks — a new property/constant/enum/signature). Then write the
minimal code. Run the test and confirm it passes. The `## Verification`
section in `requirements.md` must reference the exact test command.

## 4. Gate and handoff

Run the non-escapable gates:

```bash
brainiac check --spec <spec-dir>   # PII/secret + clarification + verification gate
brainiac plan --spec <spec-dir>    # validate the task graph
```

If either gate fails, fix and re-run. The skipped gates (`analyze`,
`clarify`, `reconcile`) are bypassed — but the gates above are mandatory.

Then hand off:

```bash
brainiac handoff --spec <spec-dir> --repo <repo-path>
```

## 5. Report

Report what was skipped and what ran:

```
quick: done
  repo: <repo>
  spec: <spec-dir>
  skipped: research, initiative, epic, clarify, analyze, reconcile
  ran: specify, check --spec, plan --spec, handoff
  TDD: yes
```
