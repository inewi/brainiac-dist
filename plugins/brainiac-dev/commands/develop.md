---
description: Full development session — pick a task, implement with TDD, debug, review, verify, and hand off. The complete dev workflow from start to finish. Use when beginning work on a repo or continuing after a previous task.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Skill
---

# Development Session

$ARGUMENTS

This is the complete developer workflow. It finds available tasks, guides you through
implementation with superpowers, and handles the full cycle: TDD → implement → debug →
review → verify → handoff. Runs as a continuous session — you stay in flow until the
task is done.

---

## Step 1: Find Available Tasks

First, locate the per-epic workspace. Read `.brainiac/status.json` and check for
`workspace_path`. If it's present and you're not already inside it, the epic's code
lives in a dedicated workspace under the shape `.references/.epics/EPIC-####/<repo>` —
`cd` there and re-run this step from inside it:

```bash
cd .references/.epics/EPIC-####/<repo>
```

If `workspace_path` is absent, proceed in the current directory.

Read the current repo's state:

```bash
ls specs/EPIC-*/tasks.md 2>/dev/null
```

If specs exist, read the most recent spec's `tasks.md` and `.brainiac/status.json`.
If no spec, read any `tasks.md` at the repo root and check `.brainiac/status.json`.

For each task, determine its state:

- **Available:** all `depends_on` tasks are complete in status.json. Tasks with
  `(depends_on: none)` are always available.
- **Blocked:** at least one dependency is not yet complete. List what's blocking it.
- **Done:** marked complete in status.json.

If `$ARGUMENTS` includes a task ID (e.g., `T-004`), skip directly to Step 3 with that task.
Otherwise, present the list and let the developer choose.

---

## Step 2: Choose a Task

Present available tasks in priority order:

```text
Available to develop:
  ◻ T-004: API RODO — eksport dokumentacji (depends_on: T-001 ✓, T-002 ✓, T-003 ✓)
  ◻ T-005: Dziennik audytu — rejestracja CRUD (depends_on: none)

Blocked:
  ◻ T-006: Integracja z panelem HR (blocked by: T-012 from web)

Done:
  ✓ T-001, T-002, T-003
```

Ask the developer which task to work on. If there's only one available task,
auto-select it. If nothing is available, report what's blocking each task.

Cross-repo dependencies (e.g. `blocked by: T-012 from web`) are resolved against
the **brain roll-up** — derived from each repo's published `status.json` — not the
local workspace status. The live status indicator is intra-repo only; cross-repo
readiness always comes from the roll-up.

---

## Step 3: Understand the Task

Read the task description from `tasks.md`. Read the spec's `requirements.md` and
`design.md` for context. Read the relevant source files from the grounded inventory
(`.brainiac/steering/structure.md`).

Report what you're building, why, and where in the codebase it fits:

> **T-004: API RODO — eksport dokumentacji pracownika**
>
> From requirements: WHEN pracownik składa wniosek RODO art. 15, the system shall
> udostępnić kompletny zestaw dokumentów w czasie ≤ 72h.
>
> From design: New endpoint `GET /api/employee/{id}/documents/export` in
> `src/api/documents.ts`. Returns ZIP of PDF/A files with audit log.
>
> Dependencies: T-001 (DB schema ✓), T-002 (upload service ✓), T-003 (api contract ✓).
>
> Ready to start?

Once the developer confirms, stamp the task start so handoff can record a real
duration. Pass the **same `--repo`** you will pass to handoff at Step 9 — the start
marker must land where handoff reads it, or the real duration is silently lost:

```bash
brainiac task-start --task-id <TASK_ID> --repo "<repo>"
```

---

## Step 4: TDD — Write the Failing Test

Invoke the superpowers TDD skill:

```
Skill({skill: "superpowers:test-driven-development"})
```

Write a failing test first. The test must cover the acceptance criteria from
the EARS requirement. Run it to confirm it fails.

**brainiac context for TDD:**

- The test file lives next to the implementation (e.g., `src/api/documents.test.ts`)
- Cross-repo contracts are documented in the task's `[repo:name]` annotations
- If the task depends on a contract from another repo, mock it based on the
  contract description in that repo's tasks.md

**[CHECKPOINT]** Test fails. Proceed to implementation.

---

## Step 5: Implement — Make the Test Pass

Write the minimal implementation to make the test pass. Follow brainiac conventions:

- `_` prefix for unused parameters
- kebab-case for files
- All public functions exported for grounding inventory

Run the test. If it passes, continue. If it fails, loop back.

**[CHECKPOINT]** Test passes. Proceed to verification.

---

## Step 6: Debug If Needed

If tests fail or unexpected behavior appears, invoke:

```
Skill({skill: "superpowers:systematic-debugging"})
```

**brainiac context for debugging:**

- Cross-repo: check `.references/` for upstream contracts
- Spec drift: does the code match the spec? Run `brainiac reconcile`
- Freshness: are steering docs stale? Run `brainiac check --freshness`
- PII check: did the implementation add secrets? Run `brainiac check --scan`

---

## Step 7: Verify — Confirm It's Done

Invoke the superpowers verification skill:

```
Skill({skill: "superpowers:verification-before-completion"})
```

**brainiac-specific verification:**

- Run `brainiac check` — passes all gates (paths, secrets, spec, freshness)
- The implementation matches the EARS requirements exactly
- No side effects on other tasks (check `depends_on` graph)
- All new files follow brainiac naming conventions

**[CHECKPOINT]** All gates pass. Ready for review.

---

## Step 8: Code Review

Invoke the superpowers code review skill:

```
Skill({skill: "superpowers:requesting-code-review"})
```

The review checks: correctness, test coverage, brainiac conventions compliance,
cross-repo contract adherence.

If the review finds issues, loop back to Step 5 (implement) or Step 6 (debug).
Do not proceed past a failing review.

**[CHECKPOINT]** Review approved. Ready to hand off.

---

## Step 8.5: Commit the Task

Review approved. Commit the task's code on the epic branch (the pre-commit gate runs):

```bash
git add -A && git commit -m "feat(<area>): <T-ID> <short summary>"
```

One commit per task keeps the epic branch a sequence of reviewable units.

---

## Step 9: Handoff — Mark Complete

Publish the completed task with the full form (handoff requires `--spec`; pass
`--task-id` so the throughput ledger records the real duration captured at Step 3):

```bash
brainiac handoff --spec "specs/EPIC-####-slug" --repo "<repo>" --repo-name "<repo-name>" --task-id <TASK_ID>
```

This re-gates analyze, refreshes `status.json`, appends the real task duration to
the throughput ledger (`repos/<repo-name>/throughput.jsonl`), and clears the start
marker. When `--repo` is an epic workspace under `.references/.epics/`, handoff
**auto-roots the ledger in the brain** (the path prefix before `.references/`), so
durations survive a later `workspace discard` and reach the reflect loop — no extra
flag needed. For unusual layouts outside that shape, pass `--ledger-root <brain-root>`
explicitly; the ledger must never land inside a discardable workspace.

---

## Step 9.5: Capture a Retro (best-effort)

Right after handoff returns, record what this task hit. This is best-effort — it
never blocks the session. Pass the friction tags that apply (closed vocabulary:
`spec-ambiguous`, `missing-fixture`, `cross-repo-contract`, `tooling`,
`gate-false-positive`, `skill-silent`, `skill-misleading`, `other`):

```bash
brainiac reflect capture --scope task --id <TASK_ID> --repo-name "<repo-name>" \
  --friction "<comma-separated-tags>" --why-fought "<one line, no secrets>"
```

Tag the *artifact or pipeline* condition, never an operator ("the skill was silent
on X", not "I forgot X"). Omit `--friction` if the task was frictionless.

---

## Step 10: Next Task or Done

Report what was accomplished:

> **T-004 complete.** API RODO endpoint implemented (127 lines), 5 tests passing,
> review approved. Status published.
>
> Available next:
> ◻ T-005: Dziennik audytu — rejestracja CRUD
>
> Run `/brainiac:develop` to continue, or take a break — the pre-commit hook
> keeps the gates up on every future commit.

If no tasks remain, celebrate:

> **All tasks complete.** spec EPIC-0042 is fully implemented.
> Run `/brainiac:reconcile` to verify zero drift, then the PM can close the epic.

Before ending the session, write a brief CC memory note summarizing: what was built,
key implementation decisions, gotchas discovered, and any cross-repo notes. This
persists knowledge for future sessions — the next agent starts informed, not from scratch.

---

## Session Invariants

1. **Never skip TDD.** A failing test always comes before implementation.
2. **Never bypass a gate.** If `brainiac check` fails, fix it — don't skip.
3. **Never merge without review.** `superpowers:requesting-code-review` is mandatory.
4. **Always handoff.** Every completed task updates `status.json`.
5. **One task per session.** Focus. Finish. Hand off. Then start the next.
