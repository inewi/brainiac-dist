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
- **Exit 2 (cannot-run)** → STOP and name the gate: install gitleaks, run
  `brainiac ground`, or accept that a repo without a sandbox descriptor cannot probe
  base-green here (`no-descriptor` — keep the repo suite green yourself before reviewing).
- **Exit 0** → proceed.

## 3. Plan

```bash
brainiac epic-review --plan --json
```

Read `data.lenses` (one entry per reviewer: `key`, `label`, and a ready-to-send `brief`),
`data.caps` (resolved reviewer/iteration caps + the default fix threshold), and
`data.changedFiles`.

## 4. Review

Dispatch ONE reviewer subagent per lens entry — the `superpowers:requesting-code-review`
pattern — giving each subagent its `brief` from the plan output verbatim. Reviewers are
**read-only by design**: their brief says so; do not hand them Write. Collect each
reviewer's `{"findings": [...]}` output.

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

## 7. Re-review

Run a confirming pass over the final diff (fresh reviewer subagent, same briefs' scoping
rule). A finding is **fixed** only when a re-reviewer confirms it absent — never on the
fixer's say-so. A finding the operator chose not to fix stays `open` (or `open-below-bar`
below the threshold).

## 8. Envelope + comment

Assemble the envelope at `.brainiac/reviews/EPIC-####.json`:

- `epic`, `repo`, `reviewedTipSha` (the epic tip you reviewed), `iterations`, `reviewers`,
  `floor` (the step-2 outcomes), `findings` (the FULL merged set with statuses), `verdict`.
- **The verdict is computed from the FULL findings set, never the fix selection**: any
  critical still open → `blocked` — even if the operator deliberately chose not to fix it.
  All findings fixed/refuted → `fixed-clean`; none found → `clean`.

Commit it on the epic branch (`git add -f .brainiac/reviews/ && git commit`), push, then:

```bash
brainiac epic-review --comment .brainiac/reviews/EPIC-####.json
```

Non-GitHub remote or no `gh` → the CLI prints the rendered comment for manual pasting.

> **Substring-masking caveat:** the secret scan is substring-tolerant — a legitimate
> finding whose evidence quotes code like `authToken = getToken(req)` can be
> masked-and-blocked. If a masked finding looks like a false positive, resolve it by
> editing the finding's evidence (drop the matched substring), NOT by overriding the
> verdict at finalize.

## 9. Report

Print the verdict. If `blocked`, tell the operator plainly: `handoff --finalize-epic`
will refuse until the critical findings are fixed and re-reviewed — or they pass
`--override-review-block "<reason>"`, which records the reason durably (PR comment + epic
amendment stamp).
