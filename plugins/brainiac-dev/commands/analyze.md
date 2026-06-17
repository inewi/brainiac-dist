---
description: Read-only cross-artifact + symbol-resolution gate for a spec the ONE WAY — checks requirement→task traceability and resolves design symbols (inventory first, live LSP fallback).
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:analyze

Cross-check an authored spec trio before handoff. brainiac specs live the ONE
WAY, in `‹repo›/specs/EPIC-####-slug/`; this command reads only that home and the
repo's grounded inventory. It NEVER reads, adapts to, or migrates a repo's legacy
spec dirs. analyze is READ-ONLY — it writes nothing and never edits the spec.

**Argument:** the spec directory, e.g. `specs/EPIC-0007-add-export`. Optional:
`--repo <path>` to point at the target repo (default: derived from the spec dir).

## 1. Run the gate

```bash
brainiac analyze --spec "specs/EPIC-####-slug"
```

The engine composes the `brainiac check` spec lint, verifies every `FR-###` /
`C-###` requirement is referenced by some task (traceability), and resolves each
`## Affected symbols` entry: a `MODIFY` symbol must exist (in the persisted
`structure.md` inventory first, then via a live `workspaceSymbol` LSP fallback),
and a `NEW` symbol must NOT already exist. The repo must be grounded — analyze
refuses an ungrounded repo and tells you to run `/brainiac:ground` first.

## 2. Act on the output

On success it prints `analyze: OK (N symbol(s) resolved, M advisory)`, exiting 0.
Advisories (printed as `advisory: [<kind>] …`, e.g. a `stale-inventory` when
HEAD moved since grounding) do NOT fail the gate, but a stale inventory is worth
re-grounding before handoff.

On an error finding it lists each `analyze: [<kind>] <detail>` and exits 1. Fix
the cause in the spec, then re-run until it returns 0:

- `orphan-requirement` — an `FR-###`/`C-###` no task references. Add a task that
  implements it (or remove the requirement).
- `unresolved-symbol` — a `MODIFY` symbol that exists in neither the inventory
  nor the live LSP. Cite the correct stable name, or re-ground a stale inventory.
- `phantom-new-symbol` — a `NEW` symbol that already exists. Mark it **MODIFY**.
- `spec-lint` — a PII/clarification/verification/placeholder violation. Resolve
  it (see `/brainiac:clarify` for clarification markers).

Only report analyze as green once it exits 0; it is the precondition
`/brainiac:handoff` gates on.
