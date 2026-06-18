---
name: cognitive-steering
description: Thinking patterns for spec-driven development. Apply when planning, analyzing, or making decisions. Structures thought to prevent common failure modes.
user-invocable: false
---

# Cognitive Steering

Structured thinking patterns that prevent the most expensive mistakes in spec-driven development.

## Pattern 1: Dependency-Chain Thinking

**Always walk backwards from the goal.**

When you know what you need to achieve, trace the dependency chain backwards to find the true starting point.

```
Goal: "Implement feature X"
  └─ What must exist before X can be built?
       └─ What must exist before THAT can be built?
            └─ Continue until you hit solid ground.
```

This prevents:

- Starting work that's blocked by upstream dependencies
- Building on assumptions that haven't been validated
- Creating plans that look complete but have hidden prerequisites

### Application

- **Planning**: Before committing to a timeline, walk every task's dependency chain
- **Debugging**: When something fails, trace backwards to find the root cause
- **Handoffs**: Before handing off, verify the full chain is resolved

## Pattern 2: Contract-First Thinking

**Define the interface before the implementation.**

When two things need to interact, define the contract between them first.

```
Instead of: "Build service A, then build service B, then figure out how they talk"
Do: "Define how A and B will interact, then build both to that contract"
```

This prevents:

- Integration failures discovered late
- Rework when interfaces don't align
- Ambiguous responsibilities between components

### Application

- **Cross-repo work**: Define the contract spec before implementing in either repo
- **API design**: Write the OpenAPI/gRPC spec before writing handlers
- **Data models**: Define the schema before writing queries

## Pattern 3: Status-Truth Thinking

**The checkbox state IS the reality.**

`tasks.md` checkboxes are the single source of truth for what's done. If the code is done but the checkbox isn't checked, the task isn't done. If the checkbox is checked but the code doesn't work, the task isn't done.

```
Status truth = tasks.md checkboxes
Not: "I think it's done"
Not: "The code looks right"
Not: "It worked on my machine"
```

This prevents:

- Handing off work that's actually incomplete
- Starting dependent tasks on false assumptions
- Status reports that don't match reality

### Application

- **Before handoff**: Verify every checkbox in the task bundle
- **Before starting a task**: Verify all `depends_on` tasks are checked
- **After implementation**: Check the box only when tests pass

## Pattern 4: Scope-Boundary Thinking

**Do what the spec says. Not more, not less.**

Every task has a scope defined by its description and the spec it implements. Work outside that scope is either:

- A new task (create it)
- A dependency (declare it)
- Out of scope (ignore it)

```
Task: "Implement login endpoint"
  └─ In scope: POST /auth/login, validate credentials, return JWT
  └─ Out of scope: Password reset, session management, audit logging
  └─ If you discover you need password reset: create a new task
```

This prevents:

- Scope creep that delays delivery
- Changes that break unrelated specs
- "While I was here" fixes that create new bugs

### Application

- **During implementation**: If you're tempted to fix something unrelated, create a task instead
- **During review**: Check that changes match the task scope exactly
- **During planning**: Break tasks down until each has a clear, bounded scope

## Pattern 5: Failure-Mode Thinking

**Before building, ask "how will this break?"**

For every significant decision, identify the failure modes and design mitigations upfront.

```
Decision: "Use Stripe for payments"
  └─ Failure mode: Stripe API is down
       └─ Mitigation: Queue payments, retry with backoff
  └─ Failure mode: Webhook delivery fails
       └─ Mitigation: Polling fallback, idempotent processing
  └─ Failure mode: Invalid card data
       └─ Mitigation: Client-side validation, clear error messages
```

This prevents:

- Surprises in production
- Missing error handling
- Incomplete specifications

### Application

- **During design**: For each component, identify 3 failure modes
- **During specification**: Add requirements for each failure mode
- **During implementation**: Handle each failure mode explicitly

## Using These Patterns

These patterns are not sequential steps. They're lenses to apply as appropriate:

- **Starting work?** Apply dependency-chain thinking
- **Designing interfaces?** Apply contract-first thinking
- **Checking progress?** Apply status-truth thinking
- **Scoping changes?** Apply scope-boundary thinking
- **Making decisions?** Apply failure-mode thinking

The goal is to internalize these patterns so they become automatic. When in doubt, start with dependency-chain thinking - it catches the most expensive mistakes.
