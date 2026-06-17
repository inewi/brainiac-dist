---
description: Author a brainiac spec the ONE WAY — scaffold specs/EPIC-####-slug/, then write grounded requirements/design/tasks and gate with check --spec.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:specify

Author a new spec for a change, the ONE WAY. brainiac uses its OWN uniform
convention everywhere: its home is `‹repo›/specs/EPIC-####-slug/` and exactly
ONE template trio (`requirements.md`, `design.md`, `tasks.md`). It NEVER reads,
adapts to, or migrates a repo's legacy spec homes. You write ONLY into
`specs/EPIC-####-slug/`.

**Argument:** the change title (a short human phrase). Optional: `--repo <path>`
(target repo, default the current repo), `--epic EPIC-####` (reuse an id).

## 1. Confirm the target repo is grounded

The spec must be authored against a grounded inventory. Check for the steering
file:

```bash
test -f "<repo>/.brainiac/steering/structure.md" && echo grounded || echo ungrounded
```

If `ungrounded`, STOP and tell the operator:

> This repo is not grounded yet. Run `/brainiac:ground` first, then re-run
> `/brainiac:specify`.

Do not scaffold an ungrounded repo — `brainiac specify` will refuse anyway.

## 2. Scaffold the ONE WAY spec home

Run the scaffolder. It mints (or reuses) the epic id and creates the template
trio under `specs/EPIC-####-slug/`:

```bash
brainiac specify "<title>" --repo "<repo>"
```

Add `--epic EPIC-####` to reuse an existing id. The command prints the
`epicId`, the created `dir` (always `specs/EPIC-####-slug`), and the three
file paths. If it refuses (ungrounded, or the dir already exists), read the
printed error, fix the cause, and re-run. brainiac will not touch any path
outside `specs/EPIC-####-slug/`.

## 3. Author the content, GROUNDED in the inventory

Read the steering inventory before writing a word:

```bash
cat "<repo>/.brainiac/steering/structure.md"
cat "<repo>/.brainiac/steering/tech.md"
cat "<repo>/.brainiac/steering/product.md"
cat "<repo>/.brainiac/steering/design-system.md"
```

Then fill the scaffolded files in `specs/EPIC-####-slug/`. The spec supports an
integrated mockup/prototyping pipeline with three tiers:

| Tier | What | When |
|---|---|---|
| 1 | `## Screen structures` section in `design.md` | Always |
| 2 | Wireframes (SVG flow diagrams) in `mockups/wireframes/` | Agent-suggested |
| 3 | Detailed mockups in `mockups/detailed/` | Agent-suggested |

### 3a. Write `requirements.md`

Write `## Context`, then `## Requirements` as EARS-style bullets. When a
requirement is computational, express it as the I/O contract table. Write
`## Out of scope`. ALWAYS write a runnable `## Verification` check.

### 3b. Evaluate UI impact

Scan requirements + grounded inventory for UI surfaces using three criteria:

(a) requirements mention screen, surface, view, page, modal, or dialog keywords,
(b) grounded inventory contains UI framework components (PascalCase exports from
.tsx/.jsx files), (c) requirements contain route or endpoint patterns serving
HTML or renderable content.

**No UI detected:** "This appears to be a backend-only epic — skip wireframes? [Y/n]"
If PM confirms, go to step 3e (design.md) with "No UI changes."

**UI detected:** "This epic touches N screens: [list]. Generate wireframes? [Y/n/s]"

- [Y] Yes, generate wireframes for all screens
- [n] Skip, go to design.md
- [S] Pick specific screens (presents numbered list; hidden if only one screen)

**Ambiguous:** If requirements are unclear, ask PM for clarification rather than
guessing. On reverse mismatch (agent detects UI, PM disagrees), PM enters [n]
and agent records the decision in design.md.

### 3c. Generate wireframes (if PM confirmed)

Generate low-fidelity SVG wireframes into `mockups/wireframes/`:

- **Screen flow diagram:** Screen connections (navigation, modals, transitions)
- **Per-screen layouts:** Box-level placement of key elements
- **State coverage:** Loading, empty, error, populated for each screen
- **Format:** SVG for web; device-frame SVG overlays for React Native (detected
  from `design-system.md` render_target field)

Present: "Wireframes generated. Review and approve? [Y/n]"

- [Y] Accept → proceed to detailed mockups
- [n] Skip → go to design.md

**Iteration (max 3 rounds):** PM provides feedback as plain text. Agent makes
changes and re-presents. After 3 rounds without agreement, record the
disagreement in design.md under `## Open Decisions` and proceed.

**Fallback:** If SVG generation exceeds token limit, fall back to ASCII-art
diagrams with a note.

### 3d. Generate detailed mockups (if PM confirmed)

Detect design system from `.brainiac/steering/design-system.md`:

"Wireframes approved. Found [Name] ([N] components). Generate detailed mockups? [Y/n/c]"

- [Y] Use detected design system
- [n] Skip, wireframes are sufficient
- [c] Custom: specify a different component library

Generate hi-fi mockups using design system components into `mockups/detailed/`:

- **Web:** HTML+CSS or high-fidelity SVG using design system tokens
- **React Native:** JSX+StyleSheet or layout JSON with Yoga-compatible flexbox

**PII-safe content:** All emails use @example.com. All URLs use
<http://example.com>. Never use real values from inventory or source files.

**Accessibility:** WCAG 2.1 minimums (44×44 touch targets, focus outlines,
contrast ratios). SVG mockups: `role="img"`, `aria-label`. React Native:
`accessibilityRole`, `accessibilityLabel`, `accessibilityState`.

**Iteration:** Up to 3 rounds (same protocol as wireframes).

**Missing components:** Render with dashed-outline placeholder
`[-- ComponentName (NEW) --]`. Auto-create task in tasks.md under
`## New components`.

**Fallbacks:** If design system detection fails, use generic component set with
a warning. If token budget exceeded, reduce screen count (most complex first)
and note limitation.

### 3e. Write `design.md`

Write `## Approach`, `## Affected symbols` (cite stable names, mark NEW/MODIFY),
and `## Data / contracts`. Fill the `## Screen structures` section:

- If wireframes/mockups exist: enrich with layout details, element references,
  and state annotations from those artifacts.
- If no UI changes: write "No UI changes."
- Verify `<!-- SCREEN-STRUCTURES-PLACEHOLDER -->` is replaced (the gate will
  fail otherwise).

### 3f. Write `tasks.md`

Write the `## Tasks` checklist. Each UI task references its mockup using a
relative path from the spec root:

```
- [ ] T-003: Build DashboardKpiGrid → mockups/detailed/dashboard.html
```

If missing components were identified during detailed mockup generation, add
a `## New components` section:

```
- [ ] T-00N: Create FilterChip component (needed by dashboard filter bar)
```

Where you are unsure of a decision, leave a `[NEEDS-CLARIFICATION]` marker in
place — `/brainiac:clarify` resolves these later. Never invent a fact about the
repo; cite the inventory or mark it for clarification.

## 4. Gate the spec

Lint the authored spec. This is the PII/secret gate plus the
clarification/verification gate:

```bash
brainiac check --spec "specs/EPIC-####-slug"
```

Fix every violation before declaring done:

- `pii` — remove the secret/PII; never echo the raw value.
- `unresolved-clarification` — either resolve it now or hand off to
  `/brainiac:clarify`.
- `missing-verification` — add the `## Verification` runnable check.
- `placeholder` — replace any `TODO`/`TBD`/`FIXME`.

Re-run `brainiac check --spec` until it returns 0. Only then report the spec as
authored, naming the `epicId` and the `specs/EPIC-####-slug/` directory.
