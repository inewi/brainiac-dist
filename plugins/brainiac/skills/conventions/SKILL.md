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

**The epic home summarizes; the spec decides.** `epics/EPIC-####/epic.md`'s Goal states
the *outcome*; contract, storage, and security decisions live in the spec trio and are
pointed to, never restated. A restated decision creates a second home for one fact, and
the second home drifts the moment a grill or clarify pass updates the spec (EPIC-0013's
Goal carried "plaintext — encryption deferred" for days after the spec switched to
per-field encryption at write time). If the Goal must mention such a decision, cite the
spec section instead of repeating its content.

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
- Minting is collision-free across devboxes: with an `origin` configured, every mint reserves
  the id first via a unique ref on `origin` before persisting the local counter. Minting
  **refuses** when run from a git repo that is not the brain root, and refuses loudly when
  `origin` is configured but unreachable — it mints locally, unreserved, only for a brain
  with no `origin` at all or a registry path outside any git repo.

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

## `[red]` — test-first tasks

A task whose new tests are **expected to fail** until a later task fixes the code MUST
carry the `[red]` token in its body:

```markdown
- [ ] T-003: Write failing DayOffServiceTests, confirm the red suite [red] (depends_on: T-002)
- [ ] T-004: Implement ResetAsync, make the T-003 suite green (depends_on: T-003)
```

Rules:

- The token goes AFTER the `T-###:` id — the parser matches the id first and reads `[red]`
  from the remainder, so a token placed before it drops the task from the graph entirely
- Descriptive prose ("write failing tests") is NOT enough; the machine reads only the token
- Without it the broker's verify rejects the deliberately failing suite and books the run
  failed — the task cannot pass, no matter how it is implemented
- A `[red]` commit may only ADD or MODIFY test files; verify holds it to that shape
- At most ONE red set is outstanding at a time — only its clearing task dispatches until
  the suite is green again
- `brainiac check --spec` warns (advisory) when a task reads as test-first but has no marker

### Compiled languages: split the signature out first

In C#, Java, Go, Rust or strict TypeScript a test calling a member that does not exist yet
does **not** fail red — it fails to **compile**. A `[red]` commit may only touch test files,
so a red suite is unreachable in one task: tests-only won't build, and tests-plus-stub is
refused by the scope gate. Both rules are individually right and jointly unsatisfiable.

Author it as two tasks — the signature lands first, then the suite is genuinely test-only:

```markdown
- [ ] T-003: Add the `ResetAsync(...)` signature + a `NotImplementedException` stub (depends_on: T-002)
- [ ] T-004: Write the failing `DayOffServiceTests` [red] (depends_on: T-003)
- [ ] T-005: Implement `ResetAsync`, make the T-004 suite green (depends_on: T-004)
```

Do NOT relax the gate to let a "small" stub ride along with the tests — that a red commit
cannot touch production is the entire reason red-tolerance is safe.

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
