---
name: guardrails
description: Pre-flight safety checks for brainiac operations. Apply before starting any task, committing, or handing off. Catches dependency gaps, contract violations, and spec drift before they become rework.
user-invocable: false
---

# Guardrails

Pre-flight checks that run before every significant action. These prevent the most expensive failure modes in spec-driven development.

## Dependency-Chain Thinking

**Before starting any task, walk the dependency graph backwards.**

```
Start with the task you want to do.
  └─ What must be true before this task can begin?
       └─ Is that thing done? If not, do THAT first.
            └─ Repeat until you hit something already done or has no deps.
```

This is the single most important guardrail. Starting work with unresolved upstream dependencies creates cascading rework.

### How to Apply

1. Read the task's `depends_on` clause
2. For each dependency, check if it's checked off in `tasks.md`
3. If unchecked, recursively apply this same check to THAT task
4. Only proceed when the full chain resolves to completed work

### Example

```
Task T-005: Implement billing API (depends_on: T-003, T-004)

Walk backwards:
  T-003: Define billing schema → ✓ checked
  T-004: Set up payment gateway integration → ✗ unchecked
    └─ T-004 depends_on: T-002
       └─ T-002: Provision Stripe account → ✓ checked
    └─ T-004 is unblocked, do T-004 first
  Then T-005 is safe to start.
```

## Pre-Commit Guardrails

Before every commit:

1. **Spec alignment**: Does this change implement what the spec requires? Not more, not less.
2. **Task scope**: Is this change within the current task's scope? If it touches code outside the task, either expand the task description or split the change.
3. **Contract safety**: If this change modifies an API, schema, or interface, is the contract spec updated first?
4. **Freshness**: Are any derived artifacts (generated docs, schema exports) now stale?

## Pre-Handoff Guardrails

Before handing off to another agent or human:

1. **Dependency resolution**: Are all tasks in the handoff bundle fully resolved (no dangling `depends_on`)?
2. **Cross-repo contracts**: If the handoff touches cross-repo dependencies, are contract specs published and grounded?
3. **Status truth**: Does `tasks.md` checkbox state match the actual code state?

## Pre-Plan Guardrails

Before committing to a plan:

1. **Grounding**: Have all affected repos been grounded (`brainiac ground`)?
2. **Reference freshness**: Is `.references/` current (`brainiac references`)?
3. **Contract-before-consumer**: For every `[repo:X]` annotation, does repo X have a contract-publishing task?
4. **Sequencing**: Has `brainiac sequencer --auto-edge` been run to detect dangling edges?

## Violations

When a guardrail fires:

- **Do not proceed** with the blocked action
- **Surface the specific gap** (which dependency, which contract, which staleness)
- **Offer the corrective action** (run the missing task, update the spec, refresh references)

The goal is fail-early, fail-cheaply. Catching a missing dependency at pre-flight costs seconds. Catching it after implementation costs hours.
