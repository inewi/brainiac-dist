---
description: Full development session — pick a task, implement with TDD, debug, review, verify, and hand off. The complete dev workflow from start to finish. Use when beginning work on a repo or continuing after a previous task.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Skill
---

# Development Session

$ARGUMENTS

This is the complete developer workflow — git-native from the first step. It enumerates the
real `epic/EPIC-####-slug` branches in your repo, drops you onto one, grounds, picks the next
unblocked task, and runs the full cycle: TDD → implement → debug → review → verify → commit →
push → handoff, then finalizes the epic when the last task lands. It runs as a continuous
session — you stay in flow until the task is done.

The mechanics are done by the `brainiac develop` verbs; the one thing that stays your judgment
is the **P7 decision gate**. Run the CLI as bare `brainiac <verb>` (the prebuilt binary is on
your PATH). If `$ARGUMENTS` names an epic (`EPIC-####`) or a task (`T-###`), jump straight to
**P3** to enter that epic — P6 then resolves the named task (or the next unblocked one) once
you're on-branch and grounded.

---

## P0 — Resume express lane

Before enumerating anything, check for an in-flight claim. If **exactly one** live active-task
marker exists under `.brainiac/active-tasks/<EPIC-####>/` **and** its epic matches your current
branch, offer the express lane:

```text
Resuming T-### on epic/EPIC-#### — [Enter] continue · [p] pick another
```

Always require one `[Enter]` — never auto-continue silently after a context switch. On resume,
still re-enter the already-current epic (a fresh clone is always ungrounded, so P4 must run every
time), then jump straight to **P5 → P8**, skipping only the P1–P2 enumeration + menu:

```bash
brainiac develop enter --epic EPIC-####
```

If **2+** live markers exist, list them and let the developer pick — never auto-resume. With no
live marker (or a branch mismatch, or an explicit `--pick`), fall through to **P1**.

---

## P1 — Enumerate epic branches

Enumerate the epic-bearing branches (local + remote-tracking) with their one-line summary and
progress, and render the JSON the verb emits:

```bash
brainiac develop --list --json
```

Each row is `EPIC-####  <title>  <summary>  done/total`. The result is a defined outcome, not a
silent empty:

- `empty: true` → print *"no epic branches — run `/brainiac:ship` first, or check you've
  fetched."*
- `offline: true` → a `git fetch` failed; proceed on local refs with an advisory, do **not**
  abort. Pass `--fetch` to opt into a fresh `git fetch --all` before listing.

Cross-repo dependencies surface here as **advisory only** — a `web:T-012 — state unknown from
here` note derived from the dependency token alone. It never blocks a pick in single-repo scope;
deterministic resolution only happens in a multi-repo/cockpit view.

---

## P2 — Epic menu

From the P1 JSON, present one row per epic. Auto-select when there is exactly one epic;
otherwise present the menu and let the developer choose which to work on.

Alongside each row, read that epic's `.brainiac/status.json` (`dev_review` and `agentic`
fields — absent means unknown, never inferred) and render a soft-gate badge: `reviewed ✓ /
agentic ✓` when both are stamped, `reviewed ✓` when only `dev_review` is set, `reviewed ✗`
when `dev_review` is explicitly `none`, or `review: unknown` when the field is absent
(an older manifest predating the stamps) or when the manifest itself is
unreadable. These badges are advisory for the human picking an epic — the broker's hard
`agentic: approved` dispatch gate (governor reason `epic-not-approved`) is unaffected by what
this menu shows.

On the **repo-upward** path (a dev ran `dev-review` from the target repo instead of the
brain), the same `agentic` field is what moves: it stays unset until `brainiac dev-review
reconcile` mirrors that repo's readiness record up into the brain — at which point this menu's
badge flips to `agentic ✓` too. The human soft-gate above is unchanged either way; the
broker's hard gate reads that identical brain-mirrored `agentic` field, never the repo's own
readiness record directly.

---

## P3 — Pick, checkout, claim

Drop onto the chosen epic. The verb resolves your scope for you (dev in-place vs a PM workspace
clone — read from the gitignored `.brainiac/local.json` sidecar, never from `status.json`),
checks out `epic/EPIC-####-slug`, and claims the marker:

```bash
brainiac develop enter --epic EPIC-####
```

Before claiming, if the picked epic's `dev_review` field is missing or `none`, stop and
confirm: "This epic has no dev-review stamp — proceed anyway? (the epic-level implementer
review is the pipeline's analysis phase; consider running `/brainiac:dev-review` from the
brain first)" — `[y]` proceed · `[n]` pick another. This is an advisory confirmation for
humans; the broker's hard agentic-approval gate is unaffected either way.

**Dirty-tree policy:** `enter` refuses on modified/staged **tracked** files and prints the
offending paths — it **never auto-stashes**. Stash explicitly and re-run:

```bash
git stash push -m brainiac-enter-EPIC-####
```

Untracked files do **not** block entry: checkout never touches them, and git itself errors if
an untracked path would be overwritten by the target branch. `enter` prints an advisory with
the untracked count — keep task commits path-scoped so scratch files are never swept in.

---

## P4 — Grounding verify

`.brainiac/steering/*` is gitignored, so a fresh clone is **always ungrounded**. `develop enter`
verifies grounding on **every** entry path (including P0 resume) before any step reads steering:

- **Steering absent** → `enter` hard-fails with the exact instruction. Run it, then re-enter:

  ```bash
  brainiac ground --scan
  ```

- **Steering present but HEAD-stale** → an opt-in advisory `steering is N commits behind —
  reground? [y/N]`, default skip. Never auto-re-ground on a HEAD your own commits moved.

---

## P5 — Context bundle

Context before code. Read the branch's `specs/EPIC-####-slug/requirements.md` and `design.md`
(the "why"), plus any `## Open Decisions` / `[NEEDS-CLARIFICATION]` history. If the repo's
`.brainiac/status.json` carries a `context` field, read it first — it is the PM-authored
one-paragraph bridge from ship's handoff, the load-bearing orientation a cold start needs
before re-deriving the spec. Then re-gate traceability and probe the code region the task
touches:

```bash
brainiac analyze --spec "specs/EPIC-####-slug"
```

Report what you're building, why, and where it fits before writing a line.

---

## P6 — Next unblocked task

Read readiness from the same `develop --list --json` envelope — each epic listing carries a
`readiness` report ordered by phase then file order (readiness is classified from the epic's
own branch ref even before checkout, so the pre-checkout menu already shows real next-task
data; `develop enter` remains the only claim gate):

```bash
brainiac develop --list --json
```

If `readiness.malformedCheckboxes` is non-zero, the tasks.md has checkbox lines that don't
parse as tasks — fix them to the `- [ ] T-###: <task> (depends_on: ...)` grammar before
picking (a task the parser can't see can never be selected, verified, or finalized).

Pick the first `AVAILABLE` task (a task with all local deps done). Auto-select when exactly one
is available. Zero-available is a defined outcome:

- **all blocked** → list each blocker (plus any cross-repo advisory) and stop.
- **all done** → the epic is complete → route to **P9**.

---

## P7 — Decision gate

This is the one step that stays your judgment — everything else is a verb.

- **Tier 1 — readiness (auto, blocking):** the criteria are testable, deps are resolved, and no
  blocking `[NEEDS-CLARIFICATION]` remains → auto-pass to **tackle**.
- **Tier 2 — spec validity (opt-in, never a gate):** the arms are **tackle · grill · clarify**.
  - **tackle** → proceed to P8.
  - **grill** → opt-in, never a gate. The PM-authored spec *deferred* its uncertain decisions;
    nothing between "understand the task" and the first failing test has attacked the design's
    decision tree. Invoke the grilling discipline, scoped to the chosen task:

    ```text
    Skill({skill: "brainiac:grill"})
    ```

    It interviews you one branch at a time, self-answering from `.brainiac/steering/` + the spec
    where it can, and records any unresolved branch as a `[NEEDS-CLARIFICATION]` marker (a side
    effect for the next `/brainiac:clarify` pass — not a forced round-trip). When the design
    feels genuinely shared, return to P8.
  - **clarify** → resolve open markers with `/brainiac:clarify`, then re-gate.

For a *true* re-spec — the task is built on a wrong premise — there is **no** lightweight
task-level respec. Point at the epic-scoped, Amendments-stamping path and stop the flow:

```bash
brainiac revise --epic EPIC-#### --reason "<what's amiss + why>"
```

Advisories that never block: open markers / an in-flight amendment (epic validity); `reconcile`
`head-moved` / `rollup-changed` (branch freshness). Single-candidate steps collapse to a
one-line confirm.

---

## P8 — Stamp start and TDD

Stamp the start so handoff can record a real duration. Pass `--epic` (namespaces the marker) and
the **same `--repo`** you will pass to handoff below, or the duration is silently lost:

```bash
brainiac task-start --task-id <TASK_ID> --epic EPIC-#### --repo "<repo>"
```

Then run the inner loop:

1. **TDD** — `Skill({skill: "superpowers:test-driven-development"})`. Write a failing test first
   that covers the acceptance criteria from the EARS requirement, and run it to confirm it
   fails. The failing test is the readiness proof — if the criteria can't be a red test, loop
   back to P7. The test lives next to the implementation; if the task depends on another repo's
   contract, mock it from that repo's `tasks.md` `[repo:name]` annotation. Run tests with the
   recommended command from `.brainiac/steering/tech.md` (`## Test command`) when present — it
   is tuned for parseable output (quiet flags on verbose stacks). In statically-typed repos
   (C#, Java, Kotlin, Swift) a test referencing a not-yet-existing symbol fails to *compile* —
   that compile error IS a valid RED for schema-shaped tasks (new property/constant/enum/
   signature), provided the error names the missing symbol from the acceptance criteria; never
   "fix the build" by creating the symbol first. When the unit under test has a wide
   constructor (≳5 dependencies), first read the constructor declaration, enumerate every
   dependency, and mirror a sibling test's mock framework, naming, and SUT-factory style
   (mocks + a `CreateSut()`-style helper) before writing the first failing test — copy the
   repo's real conventions, never invent a skeleton. **CHECKPOINT** — test fails.
2. **Implement** — write the minimal implementation to pass the test, following brainiac
   conventions: `_` prefix for unused-but-arity-required parameters, kebab-case files, all
   public functions exported for the grounding inventory. Match the SURROUNDING repo's
   conventions before adding schema elements (mirror the neighboring column/property/file
   naming — never introduce a new style next to an established one). Never hand-edit generated
   files (EF `*.Designer.cs`/`*ModelSnapshot.cs`, lockfiles, `generated/**`) — regenerate them
   with their own tool (e.g. `dotnet ef migrations remove` + re-add). Prefer transient changes
   over permanent project-file mutations — a csproj/manifest edit outlives the task, so reach
   for it last. Run the test; loop back if it fails.
   **CHECKPOINT** — test passes.
3. **Debug if needed** — `Skill({skill: "superpowers:systematic-debugging"})`. brainiac context:
   check `.references/` for upstream contracts; `brainiac reconcile` for spec drift; `brainiac
   check --freshness` for stale steering; `brainiac check --scan` for added secrets.
4. **Verify** — `Skill({skill: "superpowers:verification-before-completion"})`. Run `brainiac
   check` (passes paths, secrets, spec, freshness gates); confirm the implementation matches the
   EARS requirements exactly and touches no other task's `depends_on` graph. **CHECKPOINT** — all
   gates pass.
5. **Code review** — `Skill({skill: "superpowers:requesting-code-review"})`. Correctness, test
   coverage, brainiac conventions, cross-repo contract adherence. On findings, loop back to step
   2 or step 3 — do not proceed past a failing review. **CHECKPOINT** — review approved.
6. **Commit (path-scoped)** — stage **only** this task's paths — **never the whole tree** (no
   blanket `-A` add) — so carried-across changes, other devs' merged work, and the churned
   tracked `status.json` (which handoff owns) can't be swept into a task commit:

   ```bash
   git add -- <changed source and test paths>
   git commit -m "feat(<area>): <T-ID> <short summary>"
   ```

   One commit per task keeps the epic branch a sequence of reviewable units. The pre-commit gate
   runs automatically.
7. **Handoff — mark complete and push** — publish the completed task. Handoff re-gates analyze,
   refreshes `status.json`, appends the real duration to the throughput ledger, clears the start
   marker, and (with `--push`) pushes the epic branch:

   ```bash
   brainiac handoff --spec "specs/EPIC-####-slug" --repo "<repo>" --repo-name "<repo-name>" \
     --task-id <TASK_ID> --epic EPIC-#### --push
   ```

   Handoff warns when the working tree still has uncommitted paths — that usually means step 6's
   path-scoped commit missed files (e.g. a signature change rippling into callers/test helpers).
   Fold stragglers in with `git commit --amend` (pre-push) or a follow-up commit before moving
   on; under `--strict`, tracked modifications hard-fail the handoff.

   The push is **write-access-aware** and **degrades, never throws**: on offline / protected /
   no-write / non-fast-forward, the local commit stands, handoff prints *"committed locally on
   `epic/EPIC-####-slug`; run `git fetch origin <branch> && git rebase origin/<branch>`
   then retry"*, and exits 0. Add `--strict` to make a skipped push non-zero (for CI). Pushes are
   plain `git push -u` — **never** `--force`. When `--repo` is a PM workspace under
   `.references/.epics/`, handoff auto-roots the ledger in the brain so durations survive a
   later `workspace discard`; pass `--ledger-root <brain-root>` only for layouts outside that
   shape.
8. **Capture a retro (best-effort)** — right after handoff returns, record what the task hit
   (never blocks). Friction vocabulary: `spec-ambiguous`, `missing-fixture`,
   `cross-repo-contract`, `tooling`, `gate-false-positive`, `skill-silent`, `skill-misleading`,
   `other`:

   ```bash
   brainiac reflect capture --scope task --id <TASK_ID> --repo-name "<repo-name>" \
     --friction "<comma-separated-tags>" --why-fought "<one line, no secrets>"
   ```

   Tag the *artifact or pipeline* condition, never an operator. Omit `--friction` if
   frictionless.

Report what was accomplished and loop back to **P6** for the next task, or continue to **P9**
when the epic is done.

---

## P9 — Finalize the epic

When P6 reports all tasks done and `reconcile` is clean, push the final state and flip the draft
PR → **ready-for-review**:

```bash
brainiac handoff --finalize-epic --repo "<repo>" --base <base-branch>
```

This prints the PR URL. It does **not** auto-merge or auto-delete — review/CI merges, and the
platform (or a later cleanup verb) deletes the branch.

Before ending the session, write a brief CC memory note — what was built, key decisions,
gotchas, cross-repo notes — so the next session starts informed. Run `/brainiac:develop` again
to continue on another task or epic.

---

## Session Invariants

1. **Never skip TDD.** A failing test always comes before implementation.
2. **Never bypass a gate.** If `brainiac check` fails, fix it — don't skip.
3. **Never merge without review.** `superpowers:requesting-code-review` is mandatory.
4. **Always handoff.** Every completed task updates `status.json`.
5. **Never `--force`-push and never blanket-stage (no `-A` add).** Pushes degrade gracefully;
   commits stay path-scoped.
6. **One task per session.** Focus. Finish. Hand off. Then start the next.
7. **Never delete `.brainiac/`.** It is brainiac's runtime state (live task markers,
   telemetry, steering) — irrecoverable, not build junk. There is exactly ONE `.brainiac/`
   per repo, at the repo root; if you find a second one nested deeper, report it instead of
   tidying it away.
