---
description: Provision the brainiac convention into the current repo — detect-and-coexist with incumbents, deprecate-not-delete old artifact homes, and install the local enforcement gate. Dry-run first; apply only on explicit confirmation.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /brainiac:init — provision the brainiac convention (safely)

You are onboarding the **current repository** to the brainiac convention. Your
prime directive: **never delete anything**, **never overwrite a per-repo
constitution**, and **coexist** with incumbent tooling. This is
deprecate-not-delete. Work in two phases: PLAN (read-only), then — only after
the operator confirms — APPLY.

The brainiac CLI is available as `brainiac` (it maps to the plugin's bundled
`dist/cli.js`). If the bare `brainiac` command is not on PATH, fall back to
`npx --no-install brainiac` for every invocation below.

## Phase 1 — PLAN (read-only, no mutation)

1. Confirm you are at the repository root (a `.git` directory is present). If
   not, ask the operator for the repo root and `cd` there.

2. Produce the init plan without touching the filesystem:

   ```
   brainiac init --root . --dry-run
   ```

   This prints, line by line:
   - `host:` — `github`, `bitbucket`, or `unknown` (from the git remote).
   - `incumbents:` — allowlisted tool homes already present (e.g. `.memex`,
     `.specify`, `.superpowers`, `.agents`, `.claude`, `AGENTS.md`,
     `CLAUDE.md`). These will be **left untouched** — detect-and-coexist.
   - `deprecations:` — files under the repo's configured deprecated globs
     (from `.brainiac/config.json`). These will be **marked deprecated, not
     removed**.
   - `hooksToInstall:` — the gates to wire (`pre-commit`).
   - `willDelete:` — always `false`. brainiac never deletes.

3. **Recommend a content secret-scanner (advisory, never failing).** Check
   whether `gitleaks` is available on PATH:

   ```
   command -v gitleaks
   ```

   If it is **not** found, recommend installing it (e.g. `brew install
   gitleaks`) so the Phase-1 content scanner can run alongside brainiac's
   path-based denylist gate. This is a **recommendation only** — do not install
   it, do not block, and do not fail `:init` if it is absent. The path-based
   `brainiac check` gate works with or without it; the content scanner is the
   Phase-1 deepening (design §14.1). This follows detect-and-coexist: an
   existing scanner is detected and left in place, never replaced.

4. Present the plan back to the operator in plain language. Explicitly call out:
   - Which incumbents will be **coexisted with** (named, not deleted).
   - Which paths will be **deprecated-not-delete** (a deprecation marker /
     window, never an in-place delete).
   - That the `pre-commit` hook will run `brainiac check` before each commit.
   - Whether `gitleaks` was found, and the install recommendation if not.
   - That `willDelete` is `false`.

5. **Ask the operator to confirm** before any change:
   `"Apply this plan? It installs the pre-commit gate and marks the listed
   paths deprecated (nothing is deleted). [yes/no]"`
   If the answer is anything other than an explicit yes, **stop here** and make
   no changes.

## Phase 2 — APPLY (only after explicit confirmation)

Apply is transactional and additive. Do these in order:

1. **Install the enforcement gate** (idempotent — safe to re-run):

   ```
   brainiac install-hooks --root .
   ```

   This wires `npx --no-install brainiac check` into `.husky/pre-commit` when
   husky is present, otherwise into `.git/hooks/pre-commit`, and makes the hook
   executable.

2. **Deprecate-not-delete** the competing homes listed in the plan. For each
   path under `deprecations:`, leave the file in place and record it as
   deprecated (e.g. add it to a `DEPRECATED.md` notice at the repo root naming
   the path, the canonical replacement home, and the removal window). **Do not
   `rm`, `git rm`, or move** any source file. If `deprecations:` was empty,
   skip this step.

3. **Coexist with incumbents.** Do not modify or remove any path listed under
   `incumbents:` (`.memex` in particular is out of scope and must be left
   exactly as-is). Reference an existing per-repo constitution (e.g.
   `.specify/memory/constitution.md`) rather than copying or overwriting it.

4. **Verify the gate works** before declaring success:

   ```
   brainiac check --root .
   ```

   Exit code `0` means the tree is clean. A non-zero code means a denylisted or
   deprecated path is present — report it; do not suppress it.

5. **Report** what changed: the hook path installed, any deprecation notices
   added, and confirm that **nothing was deleted** (`willDelete: false`).

## Guarantees (restate to the operator)

- **Deprecate-not-delete.** Old artifact homes are marked, never removed.
- **Never delete.** No `rm`/`git rm`/destructive move is ever run by this
  command.
- **Never overwrite a per-repo constitution.** Existing repo governance is
  referenced, not replaced.
- **Detect-and-coexist.** Incumbent tools (`.memex`, `.specify`,
  `.superpowers`, `.agents`, `.claude`) are detected and left intact.
