---
description: Human epic-end review — deterministic floor, one reviewer subagent per lens from the CLI plan, operator-chosen fix threshold, TDD fixes, confirming re-review, then the committed verdict envelope + PR comment. Run in the target repo on the epic branch when finishing an epic by hand.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Skill
---

# /brainiac:epic-review

$ARGUMENTS

The human path of the epic-end review: the same review the autonomous broker runs when an
epic drains, driven interactively. The CLI verb owns the deterministic parts (floor, lens
plan, comment); you drive the reviewers, the fixes, and the envelope. **The committed
envelope (`.brainiac/reviews/EPIC-####.json`) is the verdict SSOT — the PR comment is a
mirror, and `handoff --finalize-epic` reads the verdict from origin, not from this
session.**

## 1. Locate

Confirm the cwd is a target repo checked out on an `epic/EPIC-####` branch, with a spec
trio under `specs/EPIC-####-*/`. Not there → stop with guidance (`git branch --show-current`,
`brainiac develop --list`). Derive the epic id from the branch name.

## 2. Floor

```bash
brainiac epic-review --floor
```

- **Exit 1 (red)** → STOP. Tell the operator which gate failed (base / analyze / gitleaks)
  — never review a broken tree; fix the tree first.
- **Exit 2 (cannot-run)** → STOP and name the gate: install gitleaks, or run
  `brainiac ground`. For `base=cannot-run (no-descriptor)` — a target repo has no sandbox
  descriptor; the floor prints the exact `--attest-base` command — ask the operator for the repo's suite command and re-run the floor with it as
  the base gate:

  ```bash
  brainiac epic-review --floor --attest-base "<suite command, e.g. dotnet test>"
  ```

  A passing suite records `base=operator-attested` (the command, its exit code, the time and
  the tip) — a passing gate; a failing one is `red` (exit 1).
- **Exit 0** → proceed.

## 3. Plan

```bash
brainiac epic-review --plan --json
```

Read `data.lenses` (one entry per reviewer: `key`, `label`, and a ready-to-send `brief`),
`data.caps` (resolved reviewer/iteration caps + the default fix threshold), and
`data.changedFiles`.

Read `data.priorPosts` too — everything anyone has posted on the epic PR (comments, inline
comments, review bodies, the lane's findings and replies, the committed envelope). Each lens
`brief` already carries it as fenced data, with the `considered` contract. `status` tells you what
you got: `ok` (with `ids`), `no-pr` (no PR yet — nothing posted), or `unavailable` (with a
`reason`: `gh` missing, a read failed). On `unavailable`, say so to the operator before
reviewing — the review then runs WITHOUT what others posted, and the envelope must not read as if
it had.

## 4. Review

Dispatch ONE reviewer subagent per lens entry — the `superpowers:requesting-code-review`
pattern — giving each subagent its `brief` from the plan output verbatim. Reviewers are
**read-only by design**: their brief says so; do not hand them Write. Collect each
reviewer's `{"findings": [...], "considered": [...]}` output.

When `data.priorPosts.status` is `ok`, a reviewer must list EVERY id in `data.priorPosts.ids`
under `considered` with one status — `agreed`, `re-verified`, `disputed` (with `evidence`) or
`superseded`. A prior claim may be re-checked, never silently dropped. A reply that leaves an id
out, uses another status, or disputes without evidence is **rejected**: send it back to the same
reviewer. The check is `validateConsidered(considered, ids)` in
`src/review-context/pr-conversation.ts`.

## 5. Merge + choose the fix threshold

Merge the findings (dedupe by file + line + claim substance; keep the highest severity on
a collision). Show the operator the deduped list, then ask which **threshold** to fix —
one ordinal choice: **minor** (fix minor and above), **major**, **critical**, or **none**.
Not a per-finding multi-select: the threshold is the contract.

## 6. Fix

For every finding at/above the chosen threshold, fix via the normal TDD loop
(`superpowers:test-driven-development`): failing test → minimal fix → green. Keep each fix
scoped to what the finding cites. Re-verify with `brainiac check` + the repo suite before
moving on.

**Reachability.** A finding about a state production cannot reach is refuted, not fixed: trace
the load path (who calls this, with what values, from which entry point) and cite it. No guard,
no test and no requirement is added for it, handling that already exists for it is removed, and
it never becomes a `[review]` task. A prior post that says "unreachable" is a prior claim:
re-verify it against the code yourself and list it under `considered` — do not act on the
finding until you have.

**Test-only visibility.** Raise a finding (minor) for code made public or internal — or reached
through `InternalsVisibleTo`, or made non-private/non-static — only so a test can reach it.
Look in the target repo's `.claude/rules/` (a testing rule) for a visibility ladder first: when one
exists, cite that rule and name the rung the change skipped; when none does, ask for the usual
order (an existing public entry point, then extract a class, then ONE public seam with the
operator's OK; `static` is fine for pure logic; no `InternalsVisibleTo` for a single test). A
widening that serves production callers, or a seam the operator approved, is not a finding. It is
not forbidden, so do not call it that.

## 7. Re-review

Run a confirming pass over the final diff (fresh reviewer subagent, same briefs' scoping
rule). A finding is **fixed** only when a re-reviewer confirms it absent — never on the
fixer's say-so. A finding the operator chose not to fix stays `open` (or `open-below-bar`
below the threshold).

## 8. Finalize the round

Write the round's findings file (anywhere outside the repo, e.g. `$TMP/EPIC-####-round.json`):

```json
{
  "iterations": 1,
  "reviewers": 3,
  "floor": { "base": "green", "analyze": "green", "gitleaks": "green" },
  "baseAttestation": { "command": "…", "exitCode": 0, "at": "…", "tipSha": "…" },
  "findings": [ { "severity": "major", "file": "src/a.ts", "line": 3, "claim": "…", "evidence": "…", "status": "fixed", "fixedIn": "abc1234" } ],
  "considered": [ { "id": "…", "status": "agreed" } ]
}
```

- `floor` is the step-2 outcomes. `baseAttestation` is the line `--floor --attest-base` printed,
  at the **top level** of the file (never inside `floor`) — required when `floor.base` is
  `operator-attested`.
- `findings` is the FULL merged set with statuses (`id`, `provenance` default). A finding that
  matches a decision the operator recorded in the spec (`[DECISION: …]`, or a bullet dated
  `(operator YYYY-MM-DD …)` in `design.md`) gets `status: "by-design"`, severity `info`, and
  `decision` quoting it with its `design.md:<line>` — never `refuted`.
- `considered` lists EVERY id in `data.priorPosts.ids` (step 3).
- Do **not** put a `verdict` in the file: it is computed from the floor and the FULL findings set,
  never the fix selection — any critical still open → `blocked` (even if the operator chose not to
  fix it); all fixed/refuted → `fixed-clean`; none → `clean`. A file whose `verdict` disagrees is
  refused.

Commit every fix first (the envelope names the tip it reviewed), then:

```bash
brainiac epic-review --finalize-round <findings.json> [--brain-root <path to the brain checkout>]
```

One verb, in this order, each step reporting what it did: **validate** (the schema, and
`validateConsidered` against the plan's prior-post ids — a round that omits a prior claim is
refused here) → **write** `.brainiac/reviews/EPIC-####.json` → **commit** it (`-f`, hooks run) →
**readiness** (refresh + commit the in-repo readiness record) → **push** the epic branch →
**comment** (EDIT the existing verdict comment on the PR — a new one only when none exists; no gh /
non-GitHub / no PR prints the rendered comment for pasting) → **reconcile** (needs
`--brain-root`; without it the verb prints the exact `brainiac dev-review reconcile` command to run
at the brain). A failed step stops the rest and is named (`step 'push' failed — …`, with what had
already been done); fix the cause and re-run the verb.

If a fix changed a spec file and the repo's `handoff.json` links a Jira task, offer — never post
unasked — a short note on that task saying what changed:

```bash
brainiac jira comment --spec specs/EPIC-####-slug --body-file <a markdown file with the note>
```

> **Substring-masking caveat:** the secret scan is substring-tolerant — a legitimate
> finding whose evidence quotes code like `authToken = getToken(req)` can be
> masked-and-blocked. If a masked finding looks like a false positive, resolve it by
> editing the finding's evidence (drop the matched substring), NOT by overriding the
> verdict at finalize.

## 9. Report

Print the verdict. If `blocked`, tell the operator plainly: `handoff --finalize-epic`
will refuse until the critical findings are fixed and re-reviewed — or they pass
`--override-review-block "<reason>"`, which records the reason durably (PR comment + epic
amendment stamp). A blocked verdict also outlives a `/brainiac:revise`: re-run this command to
clear it.

This is the ONE review of the epic end: the PR review lane runs only when someone posts
`/brainiac review`, and a locally developed epic is not sent to the broker host for a second one.
