---
name: grill
description: Relentlessly stress-test an already-CHOSEN plan or design before build — walk every branch of the decision tree, one question at a time, recommend an answer, self-answer from the grounded inventory. Use when a spec, task, or epic design is authored and you want to attack it before TDD locks the approach in, or when the operator uses any 'grill' trigger phrase.
user-invocable: false
allowed-tools: Read, Glob, Grep
---

# Grill

Interview the operator relentlessly about an already-chosen plan or design — whether an
authored brainiac spec or a plan described in the current conversation — until you reach
a genuinely shared understanding. Walk down each branch of the design tree, resolving the
dependencies *between* decisions one at a time. For every question, state your
**recommended answer** first, then ask.

Ask **one question at a time**, waiting for the answer before the next. A wall of
questions is bewildering and gets skimmed.

## What grill is — and what it is NOT

grill is the **convergent plan-ATTACKER**. It runs *after* a plan exists and *before*
the approach hardens (before TDD in the dev path; before the task graph in the PM path).
It is the missing beat between authoring a design and committing to it.

- It is **not** brainstorming (the divergent plan *generator* — that runs earlier).
- It is **not** `/brainiac:clarify`. clarify **resolves** existing `[NEEDS-CLARIFICATION]`
  markers, capped at 5, after authoring. grill is unbounded and **adds** markers for the
  branches it surfaces. **grill never resolves a marker — that is clarify's job.** Keep
  the boundary crisp so the two interviews never re-litigate each other.

## Self-answer from the grounded inventory, not raw source

If a question can be answered without bothering the operator, answer it yourself — but
read **only** the grounded inventory under `.brainiac/steering/` (`structure.md`,
`tech.md`, `product.md`, `design-system.md`) and the authored spec
(`requirements.md` / `design.md` / `tasks.md`). The steering inventory is brainiac's
PII-free distillation of the real checkout — that is the canonical thing to read.

When you are grilling a **free-form** idea with no spec and no grounded inventory (a
mid-conversation revalidation), ground your questions in what the operator tells you and
in the conversation so far — do not go spelunking through raw source to fill the gaps.

**Never** read outside that set. Do not open application source directly, and never read
secret/PII-denylisted paths (`.env*`, `*.pem`/`*.key`/credential files, real-data
fixtures). This skill is deliberately scoped to `Read`/`Glob`/`Grep` so it *cannot* — if
a branch truly needs a fact only raw code holds, surface it as a marker instead of
reading the code.

## Bounded-relentless

Be relentless **within the decision tree of the chosen design** — every branch, every
cross-decision dependency, every unstated edge case. But invent no new scope, and stop
the moment understanding is genuinely shared. "Relentless" is about depth on the chosen
plan, not endless tangents.

### The external-service branch is MANDATORY

For every external vendor/service the flow touches (mail provider, payment gateway,
identity provider, host API), walk two questions before the interview may end:

1. **What state does the vendor keep SERVER-SIDE that this design does not touch?**
   A fix that only lifts the internal block ships a no-op when the vendor
   independently suppresses on its own side (a provider's own hard-bounce list, its
   verify cache, its idempotency store).
2. **Where does the vendor's PROD behavior diverge from sandbox/test?** (prod-only
   short-circuits, different rate limits, verification skips).

Answer each from the spec's cited research/docs; when the spec is silent, that is an
unresolved branch — stamp `[NEEDS-CLARIFICATION]`, never assume the vendor is
stateless. This class of miss has invalidated a shipped design more than once in one
epic.

### Checkpoint every 10 questions

Relentless does not mean unbounded. After every **10 questions**, if branches still
remain, **pause and ask the operator before continuing** — do not silently roll into an
eleventh. Summarise what's resolved and what's still open, then offer the choice:

> We've worked through 10 questions. Resolved: «…». Still open: «N branches — …».
> Keep going, wrap up here, or focus on a specific branch?

Continue only on a clear yes. This is the human-in-the-loop circuit breaker: it keeps a
long grill from becoming an interrogation the operator can't escape, while still letting
a genuinely deep design get the full walk when they want it.

## Output — write nothing canonical yourself

This skill only interviews and reads; it does not write. The invoking surface records the
results, and what it records depends on which surface invoked you:

- **Artifact-scoped** (`/brainiac:grill`, or the live `/brainiac:develop` session): an
  unresolved branch becomes a `[NEEDS-CLARIFICATION]` marker in the spec — the existing
  notation owned by `specify`/`clarify`, so the next `clarify` run sees it. A decision
  that is genuinely hard to reverse, surprising, and the result of a real trade-off is
  recorded under `## Open Decisions` in `design.md` — rationale stays with the design, no
  new artifact home.
- **Free-form** (`/brainiac:grill-me`, mid-conversation): record **nothing**. The value
  is the shared understanding reached in the conversation itself. Close with a short
  recap of what is now resolved and what is still open, so the operator can decide where
  to take it next.

Do **not** create a glossary file, and do **not** author an ADR. brainiac's decision
records stay hand-curated under their existing sequential home; at most, *prompt* the
operator to write one there.

---

*The grilling discipline is adapted from the `grilling` skill in
[`mattpocock/skills`](https://github.com/mattpocock/skills) by Matt Pocock, used under
the MIT License (Copyright (c) 2026 Matt Pocock). The grounded-inventory tool-scoping,
the clarify boundary, and the write-nothing-canonical posture are brainiac adaptations.*
