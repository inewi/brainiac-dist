---
name: cross-repo-governance
description: brainiac cross-repo governance workflow — ground, specify, plan, sequencer, handoff. Apply when managing work that spans multiple repos or when using brainiac CLI verbs.
user-invocable: false
---

# brainiac Cross-Repo Governance Workflow

The full brainiac workflow for cross-repo feature delivery. Each phase has a CLI verb and a corresponding `/brainiac:<verb>` command.

> **Host note (Copilot CLI):** the `/brainiac:*` slash-commands are a Claude Code surface and do
> not exist in GitHub Copilot CLI. On Copilot, invoke the `brainiac-ship`, `brainiac-develop`, and
> `brainiac` agents and run each CLI verb as `npx --no-install brainiac <verb>`. For tool-name
> equivalents (Read → view, Edit → edit, Bash → bash, Skill → skill, …) see
> `references/copilot-tools.md`.

## Phase 1: Ground

```
brainiac ground [--scan]
/brainiac:ground
```

Inventory the repo: detect languages, list symbols via LSP, classify endpoints and UI components, render steering docs (`tech.md`, `structure.md`, `product.md`), publish `status.json`. With `--scan`, also runs gitleaks advisory.

Run this FIRST in any repo brainiac hasn't seen. Re-run when the codebase changes significantly.

## Phase 2: Specify

```
brainiac specify "<title>" [--epic EPIC-####]
/brainiac:specify
```

Scaffold a spec the ONE WAY into `specs/EPIC-####-slug/` with `requirements.md`, `design.md`, and `tasks.md`. If no `--epic` is provided, a fresh EPIC ID is minted from `registry/ids.json`.

Gate with: `brainiac check --spec <dir>`

## Phase 3: Plan

```
brainiac plan --spec <dir>
/brainiac:plan
```

Validate the `tasks.md` graph: rejects malformed tasks, unknown/self dependencies, duplicates, and cycles. Outputs a phased execution order (foundations-first).

Gate with: `brainiac plan --spec <dir>`

## Phase 4: Sequencer

```
brainiac sequencer [--spec <dir>] [--repos <csv>] [--auto-edge] [--dry-run]
/brainiac:sequencer
```

Detect dangling cross-repo edges. With `--auto-edge`, inject missing `depends_on` edges when a consumer task references `[repo:target]` that publishes a contract. Use `--dry-run` to preview before writing.

## Phase 5: Handoff

```
brainiac handoff --spec <dir> [--repo <path>] [--task-id T-###] [--dry-run]
/brainiac:handoff
```

Grade the execution harness, install the pre-commit gate, publish `status.json`, and bootstrap the target repo for implementation. This is the final governance step before development begins.

## Full Pipeline

```
ground → specify → plan → sequencer → handoff
  │         │        │         │           │
  │         │        │         │           └─ Ready for implementation
  │         │        │         └─ Cross-repo edges validated
  │         │        └─ Tasks phased, no cycles
  │         └─ Spec scaffolded, EARS-valid
  └─ Repo inventoried, steering docs rendered
```

## Cross-Repo Pattern

When work spans multiple repos:

1. Ground each affected repo
2. Specify in the primary repo; reference other repos via `[repo:name]` in tasks.md
3. Plan validates the graph per repo
4. Sequencer validates cross-repo edges (contract-before-consumer)
5. Handoff each repo when its tasks are ready

## Companion Plugins — brainiac is the Conductor

brainiac does NOT replace superpowers or pm-skills. It CONDUCTS them — telling
Claude WHEN to use each skill and WITH WHAT brainiac-specific context.

### At Every Phase, brainiac Points to the Authority

| Phase | brainiac provides | THEN delegates to |
|---|---|---|
| 1. Ground | Repo inventory, steering docs, status.json | — (pure brainiac) |
| 2. Specify | ONE WAY scaffold, EARS enforcement, ID minting | `superpowers:brainstorming` — for ideation |
| 3. Plan | Task graph validation, phase ordering | `superpowers:writing-plans` — for task decomposition |
| 4. Sequencer | Cross-repo edge detection, contract injection | — (pure brainiac) |
| 5. Handoff | Harness grading, hook install, status publish | — (pure brainiac) |
| **Implement** | Task queue, contract context, dep tracking | `superpowers:test-driven-development` |
| | | `superpowers:systematic-debugging` |
| | | `superpowers:requesting-code-review` |
| | | `superpowers:verification-before-completion` |
| | | `superpowers:subagent-driven-development` |
| | | `superpowers:finishing-a-development-branch` |
| **Verify** | Drift detection, freshness gates | — (pure brainiac) |

### PM Phase Details

**Phase 2 — Specify:** After scaffolding the spec, invoke `Skill({skill: "superpowers:brainstorming"})`.
brainiac provides the grounded inventory (what exists, which repos, existing endpoints).
superpowers provides the brainstorming framework (context → questions → approaches → design).

**Phase 3 — Plan:** After writing tasks.md, invoke `Skill({skill: "superpowers:writing-plans"})`.
brainiac provides the task graph and cross-repo annotations.
superpowers provides bite-sized task decomposition and TDD-first planning.

### Developer Phase Details

After handoff, developers run `/brainiac:develop` — a full guided session that takes a
task from start to finish in one continuous workflow:

1. **Find:** brainiac reads tasks.md + status.json, presents available tasks
2. **Understand:** brainiac loads the spec context (requirements, design, dependencies)
3. **TDD:** `superpowers:test-driven-development` — write failing test first
4. **Implement:** minimal code to make the test pass
5. **Debug:** `superpowers:systematic-debugging` — if tests fail or bugs appear
6. **Verify:** `superpowers:verification-before-completion` — gates + acceptance
7. **Review:** `superpowers:requesting-code-review` — before merging
8. **Handoff:** brainiac publishes status.json, marks task complete
9. **Repeat:** brainiac offers the next available task or celebrates completion

The developer types one command (`/brainiac:develop`) and stays in flow until the task
is done. brainiac provides cross-repo context at each step; superpowers provides the
implementation discipline.

### The Single Pipeline: `/brainiac:ship`

For the full pipeline in one command, use `/brainiac:ship "<title>" --repos <csv>`.
It walks through all 5 phases with human checkpoints at specify (requirements) and
plan (task breakdown), automating the rest and invoking superpowers at the right moments.

### pm-skills Integration

For PM craft during specify and prioritize phases:

- **PRD writing:** `/brainiac:prd` delegates to pm-skills `create-prd`
- **Prioritization:** `/brainiac:prioritize` delegates to pm-skills `prioritization-frameworks`
- **Research:** pm-skills `pm-market-research`, `pm-product-discovery`
- **Strategy:** pm-skills `pm-product-strategy`
