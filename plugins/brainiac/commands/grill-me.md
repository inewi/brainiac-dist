---
description: Grill me on anything, anytime — a free-form, relentless interview to stress-test an idea or plan mid-conversation. No brainiac artifact, no grounded repo, no writes. The "revalidate this with me right now" tool.
allowed-tools: Read, Glob, Grep, Skill
---

# /brainiac:grill-me

Stress-test whatever you're thinking about — right now, in this conversation. Unlike
`/brainiac:grill` (which is scoped to a brainiac task/epic/spec and records markers),
`grill-me` is **free-form**: point it at an idea, an approach, a half-formed plan, a
trade-off you're weighing, and it interviews you relentlessly until the thinking is
sharp. It requires no spec, no grounded repo, and it **writes nothing** — the payoff is
the shared understanding you walk away with.

Use it whenever you want one final push of scrutiny before you commit to a direction:
the PM pressure-testing a feature idea, the dev sanity-checking an approach before
opening a spec, anyone re-validating a decision out loud.

**Argument:** optional free text naming what to grill (e.g. `should we cache this
per-tenant or globally?`). With no argument, grill the plan or idea under discussion in
the current conversation.

## 1. Fix the target

Restate, in one line, the plan or idea you're about to grill — drawn from the argument or
the conversation so far — and confirm it's the right target before diving in. If it's
genuinely ambiguous, ask which of two readings you mean; otherwise proceed.

## 2. Run the grilling discipline

```
Skill({skill: "brainiac:grill"})
```

It walks every branch of the idea's decision tree one question at a time, recommending an
answer for each, and waiting for your reply before the next. It grounds its questions in
what you tell it and the conversation — it does **not** go reading raw source or
secret/PII paths to fill gaps. If a brainiac grounded inventory happens to exist and is
relevant, it may read `.brainiac/steering/` to self-answer, but it never requires one.

## 3. Recap, write nothing

When the thinking is genuinely shared, close with a short recap: what's now resolved,
what's still open, and the cleanest next step (e.g. "open a spec with `/brainiac:specify`
and run `/brainiac:grill --task` on it once it's authored"). Record nothing to disk —
that is what the artifact-scoped `/brainiac:grill` is for.
