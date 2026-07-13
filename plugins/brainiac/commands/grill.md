---
description: Relentlessly stress-test an authored design before build — grill the operator branch-by-branch over a task, an epic, or a whole spec, then record unresolved branches as [NEEDS-CLARIFICATION] markers and re-gate. The convergent plan-attacker that runs before TDD.
allowed-tools: Bash, Read, Edit, Glob, Grep, Skill
---

# /brainiac:grill

Stress-test an already-authored plan or design before you build it. This is the
convergent **plan-attacker**: it runs after a spec exists and before the approach
hardens. It surfaces the hidden cross-decision dependencies and failure branches that
`specify` deferred and that a one-shot "Ready to start?" never catches.

It pairs with `/brainiac:clarify`, it does not duplicate it: **grill ADDS**
`[NEEDS-CLARIFICATION]` markers for the branches it opens (unbounded, pre-build);
**clarify RESOLVES** them (at most 5, after authoring). grill never resolves a marker.

**Argument grammar** (pick one; spec dir is the default):

- `--task T-###` — grill me on a single task. Reads the task from `tasks.md` plus its
  `requirements.md` and `design.md` context.
- `--epic EPIC-####` — grill me on the epic. Reads the brain epic roll-up
  (`epics/EPIC-####/{epic,tasks,plan}.md`) and the per-repo spec map.
- `<spec-dir>` (e.g. `specs/EPIC-0007-add-export`) — grill the whole spec trio. Default
  when no flag is given.

## 1. Read the named artifact

Resolve the argument to the artifact(s) to attack:

```bash
# --task T-### → the task line + its spec context
grep -n "T-###" "specs/EPIC-####-slug/tasks.md"
# --epic EPIC-#### → the brain roll-up
ls epics/EPIC-####/ 2>/dev/null
# default → the spec trio
ls "specs/EPIC-####-slug"/*.md
```

Confirm the target repo is grounded (`<repo>/.brainiac/steering/structure.md` exists).
If it is not, tell the operator to run `/brainiac:ground` first — grill self-answers from
the grounded inventory, so an ungrounded repo has nothing to read.

## 2. Run the grilling discipline

Invoke the background discipline, scoped to the resolved artifact:

```
Skill({skill: "brainiac:grill"})
```

The skill interviews the operator one question at a time, walking every branch of the
chosen design's decision tree, recommending an answer for each, and self-answering from
`.brainiac/steering/` + the authored spec where it can. It reads only the grounded
inventory and the spec — never raw source, never denylisted paths. The external-service
branch is mandatory: for every vendor in the flow, what state does it keep server-side
that the design doesn't touch, and where does its prod behavior diverge from sandbox?

## 3. Record the results — markers and decisions only

grill writes **nothing canonical**. As branches resolve or stay open, record them in the
existing homes:

- **Unresolved branch** → add a `[NEEDS-CLARIFICATION] <the open question>` marker to the
  affected `requirements.md`/`design.md` line. The next `/brainiac:clarify` run resolves
  it (at most 5, one at a time).
- **Hard-to-reverse, surprising, real-trade-off decision** → record under `## Open
  Decisions` in `design.md`. Do not create a glossary file; do not author an ADR (at most
  prompt the operator to add one under the existing `docs/adr/` numbering).

Never invent a fact about the repo; cite the inventory or leave a marker.

## 4. Re-gate

Surface the markers grill added so the spec's state is honest:

```bash
brainiac check --spec "specs/EPIC-####-slug"
```

A clean grill that opened new questions will report `unresolved-clarification`
violations — that is expected and correct; hand them to `/brainiac:clarify`. grill never
weakens a gate and never touches code or tests: TDD still comes first, after the design
is sharpened.

## 5. Report

```
grill: done
  scope: <task T-### | epic EPIC-#### | spec-dir>
  branches walked: <n>
  markers added: <n>   (resolve with /brainiac:clarify)
  open decisions recorded: <n>
```
