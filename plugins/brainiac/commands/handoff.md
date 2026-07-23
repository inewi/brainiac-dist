---
description: Hand a green spec off to execution the ONE WAY — gate on analyze, grade the harness (A–D), install the brainiac check hook, publish status.json, then drive subagent-driven TDD over tasks.md.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:handoff

Promote an authored, analyzed spec to execution. brainiac specs live the ONE WAY,
in `‹repo›/specs/EPIC-####-slug/`; handoff reads that home and writes ONLY the
gated `.brainiac/status.json` plus the pre-commit hook. It is transactional and
dry-run-able — it halts and reports rather than half-applying.

**Argument:** the spec directory, e.g. `specs/EPIC-0007-add-export`. Optional:
`--repo <path>` (target repo), `--repo-name <name>` + `--task-id T-###` (record
real task duration in the throughput ledger), `--context "<paragraph>"` (ship's
PM-authored one-paragraph bridge — the load-bearing design context stamped into
`status.json`'s `context` field so a cold dev agent, esp. the autonomous broker,
starts oriented before re-deriving the spec), `--dry-run` (grade + report, write
nothing).

## 1. Gate and publish

```bash
brainiac handoff --spec "specs/EPIC-####-slug" --repo "<repo>"
```

handoff first re-runs `analyze` as a hard gate — if it surfaces error findings it
prints `handoff: BLOCKED` and writes nothing; fix the spec (see `/brainiac:plan`
and `/brainiac:analyze`) and re-run. On a green analyze it grades the repo's
execution harness (A–D over test runner / hook gate / CI), installs the mandatory
`brainiac check` pre-commit hook, and publishes a fresh `.brainiac/status.json`.
Use `--dry-run` first to preview the grade and TODOs without writing.

## 2. Act on the output

It prints the `harness grade:` line, any `todo:` items (and a CI TODO when CI is
absent), the installed `hook:` path, the published `status:` path, and a
`--- bootstrap ---` block. Resolve the harness TODOs so the repo can keep the
gate green during execution.

## 3. Drive execution — subagent-driven, TDD ALWAYS

After a green handoff, execute the bootstrap THE ONE WAY in the target repo:

1. Open plan mode and load the spec trio (requirements/design/tasks).
2. Use `superpowers:subagent-driven-development` — dispatch ONE fresh subagent
   per `tasks.md` task, in the foundations-first order `brainiac plan` derived.
3. TDD ALWAYS: each subagent writes the failing test FIRST (in statically-typed
   repos, a compile error naming the missing symbol IS the failing test for
   schema-shaped tasks), then the minimal code to green it, then commits. Never
   ship code ahead of a test.
4. The pre-commit `brainiac check` gate is mandatory — keep it green every commit.
5. Re-run `brainiac reconcile` to confirm the published `status.json` matches the
   `tasks.md` checkboxes as tasks complete; re-handoff to re-publish progress.

Report handoff as done only once the gate exits 0, the status is published, and
the bootstrap is underway.
