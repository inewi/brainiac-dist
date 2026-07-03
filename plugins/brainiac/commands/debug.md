---
description: Systematic debugging using superpowers methodology, with brainiac-aware context — cross-repo paths, artifact locations, and brainiac logging conventions.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Skill
---

# Debug

$ARGUMENTS

## Step 1: Load the upstream debugging skill

Invoke the Skill tool:

```
Skill({skill: "superpowers:systematic-debugging"})
```

If the Skill tool returns an error (skill not found), stop and tell the user:

> superpowers is not installed. Run `brainiac setup` or `/plugin install anthropics/claude-plugins-official`, then try again.

## Step 2: Apply brainiac context

Once the systematic-debugging skill is loaded, add these brainiac-specific checks:

- **Cross-repo:** Is the bug in a dependant repo? Check `.references/` for the upstream contract. Run `brainiac sequencer` to verify `depends_on` edges.
- **Spec drift:** Does the code match the spec? Run `brainiac check --spec <dir>` and `brainiac reconcile`.
- **Freshness:** Are derived artifacts stale? Run `brainiac check --freshness`.
- **Grounding:** Has the repo been grounded recently? Check `status.json` for `generated_at`. If older than the last commit, re-ground.
- **Artifact integrity:** Run `brainiac check --scan` to verify no PII/secrets in generated artifacts.

## Step 3: Follow the systematic debugging process

The superpowers systematic-debugging skill will guide you through: reproducing the bug, isolating the cause, formulating a hypothesis, testing the fix, and verifying no regressions.

At each step, consult brainiac artifacts for context.
