---
description: Resolve a spec's [NEEDS-CLARIFICATION] markers by asking the operator at most 5 questions, one at a time, then re-gate with check --spec.
allowed-tools: Bash, Read, Edit, Glob, Grep
---

# /brainiac:clarify

Resolve the open questions in an authored spec. brainiac specs live the ONE WAY,
in `‹repo›/specs/EPIC-####-slug/`. This command reads that spec, resolves its
`[NEEDS-CLARIFICATION]` markers, and re-gates it. It never reads, adapts to, or
migrates a repo's legacy spec homes.

**Argument:** the spec directory, e.g. `specs/EPIC-0007-add-export`.

## 1. Read the spec and find the open questions

```bash
cat "specs/EPIC-####-slug/requirements.md"
cat "specs/EPIC-####-slug/design.md"
cat "specs/EPIC-####-slug/tasks.md"
grep -n "\[NEEDS-CLARIFICATION\]" "specs/EPIC-####-slug"/*.md
```

Each `[NEEDS-CLARIFICATION]` marker is one open question. If there are none,
report that the spec has no open questions and stop.

## 2. Ask the operator — AT MOST 5 questions, ONE at a time

Triage the markers and ask the operator the questions that matter, **at most 5**,
**one at a time** — present a single question, wait for the answer, then ask the
next. Prefer the highest-leverage ambiguities. Where a marker can be resolved
from the grounded inventory (`<repo>/.brainiac/steering/`) without bothering the
operator, resolve it yourself and cite the inventory instead of asking.

Keep each question concrete and answerable: offer 2-3 candidate options when you
can, and never ask for a secret or any PII.

## 3. Update the spec

For each answer, edit the spec file in place: replace the `[NEEDS-CLARIFICATION]`
marker with the resolved decision. When a clarification changes behavior, update
the affected `FR-###` requirement, the `## Affected symbols` (NEW vs MODIFY), and
the `## Tasks` checklist to match. Keep the runnable `## Verification` check
accurate — if the clarification changes what "done" means, update the check.
Never delete a marker without recording the resolved decision.

## 4. Re-gate until clean

```bash
brainiac check --spec "specs/EPIC-####-slug"
```

The command MUST end with zero `unresolved-clarification` violations. Also clear
any `pii`, `placeholder`, or `missing-verification` violations the edits
introduced. Re-run `brainiac check --spec` until it returns 0.

TDD and the runnable `## Verification` check are non-negotiable (the
constitution): a spec is not clarified until the gate is clean and the
verification check still proves the change. Only then report the spec as
clarified, naming the `specs/EPIC-####-slug/` directory.
