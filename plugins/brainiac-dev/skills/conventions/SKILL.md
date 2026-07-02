---
name: conventions
description: brainiac ONE WAY conventions — spec structure, EARS notation, ID minting, invariants, freshness stamps, and contract-before-consumer. Apply when authoring or reviewing specs, tasks, initiatives, or epics in a brainiac-conformant repo.
user-invocable: false
---

# brainiac Conventions

These are the rules that govern every brainiac artifact. They are non-negotiable.

## The ONE WAY

Every spec lives in `<repo>/specs/EPIC-####-slug/` and contains exactly three files:

| File | Purpose |
|---|---|
| `requirements.md` | EARS-format requirements. No design, no tasks — only what and why. |
| `design.md` | Technical design responding to requirements. No tasks. |
| `tasks.md` | Ordered, checkbox-tracked implementation tasks with `depends_on` edges. |

No other structure is valid. `brainiac check --spec` enforces this.

## EARS Notation

Requirements use EARS (Easy Approach to Requirements Syntax):

- **Ubiquitous:** "The system shall <action>" (always true)
- **Event-driven:** "WHEN <trigger> the system shall <action>"
- **State-driven:** "WHILE <state> the system shall <action>"
- **Optional:** "WHERE <feature> the system shall <action>"

Every requirement is testable. No "should," "could," or "might."

## ID Minting

- EPIC IDs are minted from `registry/ids.json` via `brainiac id mint EPIC`
- INIT IDs are minted from `registry/ids.json` via `brainiac id mint INIT`
- IDs are sequential, zero-padded to 4 digits (EPIC-0001, INIT-0003)
- Never hand-write an ID. Always mint.

## depends_on Edges

In `tasks.md`, tasks declare what must complete before they can start:

```markdown
- [ ] T-001: Set up project scaffolding (depends_on: none)
- [ ] T-002: Implement auth module (depends_on: T-001)
```

Rules:

- Every task MUST have a `(depends_on: ...)` clause
- Use `(depends_on: none)` for tasks with no predecessors
- No cycles allowed (enforced by `brainiac plan`)
- Tasks can depend across repos with a **repo-qualified** id: `(depends_on: billing:T-003)` (the sequencer injects these; single-repo `plan` treats a `<repo>:T-###` dep as external, not a missing local task)

## Contract-Before-Consumer

When task T in repo A references `[repo:B]`, repo B MUST have a contract-publishing task (containing: export, expose, publish, api, endpoint, contract, interface, schema, openapi, grpc, proto, route, handler, or provider). `brainiac sequencer --auto-edge` injects missing `depends_on` edges.

## Freshness

Derived artifacts carry YAML frontmatter stamps:

```yaml
---
generated_from: <sha256-of-source>
generated_at: <ISO-8601>
brainiac_convention_version: 1
---
```

`brainiac check --freshness` gates on these. Stale artifacts fail the gate.

## File Naming

- kebab-case for all brainiac artifacts
- `_` prefix for unused function parameters (TypeScript convention)
- No spaces, no emoji in artifact paths
