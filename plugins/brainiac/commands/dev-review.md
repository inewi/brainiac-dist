---
description: Epic-level implementer stress-test between handoff and develop/approve — per-repo context read, implementer-perspective grill, then gate + stamp `dev_review` on the epic home. Never autonomous; runs brain-first (epic-wide, from the brain) or repo-upward (a dev runs it from the target repo on the epic branch).
allowed-tools: Bash, Read, Edit, Glob, Grep, Skill
---

# /brainiac:dev-review

$ARGUMENTS

This is the **new pipeline stage** between `handoff` and `develop`/`approve`:

```text
ship (PM) → handoff → dev-review (here) → approve --agentic
                                         ↘ develop (human)
                                         ↘ broker/agent (hard gate)
```

`grill` (Phase 3.6 of `ship`) attacks the design from the **PM's** perspective — is the
plan coherent, are the trade-offs sound. `dev-review` attacks it from the
**implementer's** perspective, one question: *could I build this exactly as written?*
It runs once per epic, over every affected repo, and its pass/fail is what
`brainiac approve` requires before an epic can become agent-dispatchable — no dev
review, no autonomous run.

**Argument:** `--epic EPIC-####` — the epic to review. There is no default and no
per-task or per-spec mode; the review and its stamp are epic-scoped.

---

## Phase 0: Resolve the Target (hard stop — never autonomous)

`--epic EPIC-####` is **required**. If it is missing from `$ARGUMENTS`, stop and ask
the operator which epic to review — do not guess, and do not fall back to "the most
recently handed-off epic." Confirm the epic home exists before doing anything else:

```bash
ls "epics/EPIC-####-slug/epic.md"
```

If it does not exist, refuse — `dev-review` reviews an existing, handed-off epic; it
never mints (`/brainiac:ship` mints). This command touches no code and writes no
stamp until Phase 3; Phases 1-2 are read-only reconnaissance.

---

## Phase 1: Context — Read Every Affected Repo

Read the epic's `repos:` list from `epics/EPIC-####-slug/epic.md` frontmatter. For
**each** repo in that list, resolve `<repo-root>` — the repo checkout — the same way
handoff left it: the epic workspace first, the pushed branch checkout second.

```bash
# 1. epic workspace (still materialized) — <repo-root> = .references/.epics/EPIC-####/<repo>
ls ".references/.epics/EPIC-####/<repo>/specs/EPIC-####-slug"
# 2. fallback — the epic branch checkout, when the workspace was discarded post-handoff
#    <repo-root> = .references/<repo>
ls ".references/<repo>/specs/EPIC-####-slug"
```

Whichever candidate resolves is `<repo-root>`; `<spec-home>` is
`<repo-root>/specs/EPIC-####-slug`. Steering always lives at the repo root, never under
the spec home, so read it unconditionally from there:

```bash
cat "<repo-root>/.brainiac/steering"/*.md 2>/dev/null
cat "<spec-home>/requirements.md" "<spec-home>/design.md" "<spec-home>/tasks.md"
```

If **neither** home resolves for a repo, do not skip it silently — record it as a
blocking finding for that repo (spec unreachable) and carry it into Phase 3's report.
A repo dev-review cannot read is a repo it cannot clear.

---

## Phase 2: Implementer Grill — "Could I Build This Exactly As Written?"

With every reachable repo's context loaded, invoke the grilling discipline in
**implementer perspective** — a narrower brief than `ship`'s design-attacker pass:

```text
Skill({skill: "brainiac:grill"})
```

Walk each repo's spec against four implementer questions, self-answering from the
grounded inventory (`.brainiac/steering/`) wherever it settles the question:

- **Affected symbols real** — does every symbol `design.md` names (NEW or MODIFY)
  actually exist, or not yet exist, where the spec says it does?
- **Technical schema fits repo reality** — do the proposed types, migrations, and
  interfaces match the repo's actual conventions and dependencies, not an assumed
  ideal?
- **Contracts consumable** — for every `[repo:name]` cross-repo annotation, can the
  declared consumer actually reach and use what the producer publishes, in the shape
  it publishes it?
- **Task graph sane** — do `tasks.md`'s `depends_on` edges reflect a buildable order,
  with no task hiding an undeclared prerequisite?
- **Cross-repo pass** — check plan.md's contract ordering against the sequencer's
  injected edges — contracts publish before consumers.

Record every unresolved branch as a `[NEEDS-CLARIFICATION] <the open question>` marker
on the affected `requirements.md`/`design.md` line — the same notation and the same
resolver as everywhere else in brainiac. Immediately offer to resolve them:

> Dev-review added N markers. Resolve now? [clarify / later]

On `clarify`, run `/brainiac:clarify <spec-dir>` per affected repo; on `later`,
continue — Phase 3's gate will surface them again.

For each challenge the grill **resolved**, record it under `## Dev Review notes` in
`design.md` — a symbol verified real (or confirmed not-yet-existing where the spec says
NEW), a schema/migration that fits the repo's actual conventions, a `[repo:name]`
contract confirmed consumable in the shape published, a hidden prerequisite surfaced and
ordered, a cross-repo contract ordering confirmed. One bullet per load-bearing finding:
what was checked, the verdict, and anything to **watch** while building it. This is the
enrichment the dev-review grill exists to produce — the findings land in the spec the
dev/broker reads, not just the markers for the branches that stayed open. Do not
transcribe the interview; capture only what a cold builder cannot recover from the code
or the checkboxes alone.

---

## Phase 3: Gate + Stamp (all-or-nothing across repos)

Run the CLI verb from the brain repo root:

```bash
brainiac dev-review --epic EPIC-####
```

For each repo in scope it re-runs `brainiac analyze --spec <dir>` (must end green —
errors block) and checks for zero unresolved `[NEEDS-CLARIFICATION]` markers. The
stamp is **epic-level and all-or-nothing**: it writes `dev_review: <date>` to
`epics/EPIC-####-slug/epic.md` frontmatter and appends a dated `## Dev Review` entry
(one verdict line per repo reviewed) **only when every repo in scope is green** — a
partial pass stamps nothing.

On `BLOCKED`, the command prints the still-failing repos and their findings. Act on
them — resolve markers, fix the analyze violations, or reconcile a spec-unreachable
repo from Phase 1 — then re-run `brainiac dev-review --epic EPIC-####` until it
stamps.

---

## Phase 4: Seam — Print the Next Step

Once the stamp lands, print the seam into authorization, exactly:

```text
next: brainiac approve --epic EPIC-#### (interactive)
```

`dev-review` never grants agentic authorization itself — `brainiac approve` is a
**separate, interactive, never-autonomous** step that an operator runs deliberately.
`dev-review` only proves the design is implementable as written; `approve` is the
human say-so that lets the broker act on it.

---

## Repo-upward path: reviewing from inside a target repo

Everything above assumes a brain-root checkout. `dev-review` also runs from **inside a target
repo**, on the epic branch, against that repo's own `specs/EPIC-####-slug/` — no brain checkout
required. The CLI auto-detects which context it's in: an `epics/EPIC-####-slug/` directory at
the root means brain-first (Phases 0-4 above); a `specs/EPIC-####-slug/` directory with no
matching `epics/` entry means repo-first. Same command either way:

```bash
brainiac dev-review --epic EPIC-####
```

Run from the repo, Phase 1's context read and Phase 2's implementer grill still apply, scoped
to this one repo's spec. On green it writes a **readiness record** in the repo — reviewer
identity, date, and a digest of the reviewed spec content — to
`specs/EPIC-####-slug/dev-review.md`, plus a `dev_review` patch to the repo's own
`.brainiac/status.json`, and prints the seam:

```text
next: brainiac dev-review reconcile --epic EPIC-####   (run at the brain, or let the post-merge hook do it)
```

The record never touches the brain by itself. A **brain-credentialed** actor mirrors it up:

```bash
brainiac dev-review reconcile --epic EPIC-####   # or: --all, to sweep every epic
```

`reconcile` re-verifies each affected repo's readiness record (reviewer identity present + the
digest still matching the spec on disk — a spec edited after review fails the check and blocks
the mirror, no manual demote needed) and, **all-or-nothing across every repo the epic touches**,
writes `dev_review: <date>` **and** `agentic: approved` to the brain's `epic.md` in the same
act — there is no separate `brainiac approve` call on this path; the review that proves the
epic implementer-ready is the same act that authorizes the broker. The **post-merge hook**
installed on the brain's git checkout runs `brainiac dev-review reconcile --all` automatically,
so bringing a reviewed epic branch into the brain (a merge) mirrors it without an operator
remembering to run reconcile by hand.

**Brain-first + `approve` stays the alternative for brain-holding operators.** Running
`dev-review` from the brain root behaves exactly as Phases 0-4 above describe — it stamps
`dev_review` only, and the separate, interactive `brainiac approve --epic EPIC-####` remains
the authorization step for that path. Pick whichever context you're actually in; both paths
converge on the same `epic.md` fields, so a human `develop` session or the broker never has to
know which one produced them.

---

## Complete

Summarize for the operator: the epic id, the repos reviewed and their verdicts,
markers added (and whether they were resolved or deferred), and — on a clean
stamp — the `brainiac approve --epic EPIC-####` seam from Phase 4. `dev-review`
writes nothing but the stamp and, via `/brainiac:clarify`, resolved markers; it never
touches code, tests, or the task graph itself.
