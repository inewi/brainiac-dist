---
description: Inventory the current repo and provision PII-free steering docs + status.json under .brainiac/ (two-phase: dry-run, review, then --scan).
allowed-tools: Bash(brainiac ground:*), Bash(brainiac check:*), Read, Glob
---

# :ground — provision steering from the live repo

Ground the current repository: inventory its symbols, endpoints, and UI components, then write three PII-free steering docs and a `status.json` manifest under `.brainiac/`. This is the second onboarding step after `:init`.

Run this from the root of the target repo (the web or billing clone), not from the brainiac repo.

## How it protects the repo

- **Denylist-at-ingest (never reads secrets).** The file walk that feeds the inventory excludes every denylisted path before opening it — `.env`, `.env.*`, `*.pem`, `*secret*.json`, `tests/fixtures/real-payroll/**`, `id_rsa`, and the rest of `denylistGlobs`. brainiac never ingests a denylisted file, so denylisted content cannot reach an artifact in the first place.
- **HARD built-in artifact gate (zero external dependency).** Before brainiac writes ANY artifact it generates (the three steering docs and `status.json`), it scans that artifact's text for PII/secret content — valid-checksum PESEL, valid-checksum NIP, secret-bearing assignments (`*_SECRET`, `*API_KEY`, `*TOKEN`, `*PASSWORD`, …), and PEM private-key blocks — using only Node + regex. Any finding HALTS the command: it writes NOTHING (transactional) and reports each finding with the value masked. This is the guarantee the Phase-1 red-team must prove.
- **Advisory gitleaks scan (non-blocking).** With `--scan`, brainiac additionally shells out to `gitleaks` to warn about pre-existing committed secrets in the repo. This is advisory only: it NEVER changes the exit code and NEVER blocks. If `gitleaks` is not installed, brainiac degrades silently and recommends `brew install gitleaks`.

## Phase 1 — dry-run and review

1. Run the dry-run. This renders all four artifacts and runs the HARD gate, but writes nothing:

   ```bash
   brainiac ground --root . --dry-run --repo-name <repo>
   ```

2. If the command prints `ground: HALTED (PII/secret in generated artifact)`, STOP. A generated artifact contained PII or a secret. Inspect the masked findings, fix the source (or extend `denylistGlobs`), and re-run the dry-run. Do not proceed until the dry-run is clean.

   **Coincidental-checksum false positive.** The gate is checksum-based, so it can HALT on a LEGITIMATE repo when a brainiac-emitted file PATH or symbol IDENTIFIER happens to contain a digit run that passes the PESEL/NIP checksum — e.g. an epoch-seconds cache file `src/cache/1600000003.ts` (a valid NIP) or an 11-digit numeric symbol suffix `WIDGET_10000000009` (a valid PESEL). Roughly 1-in-10 of 10-digit runs pass the NIP checksum and ~1-in-10 of 11-digit runs pass PESEL, so numeric ids and epoch-named cache/snapshot files are live triggers. When a `nip:`/`pesel:` finding points at such a path/identifier and you have confirmed there is NO real PII: rename the offending file (an epoch-seconds filename is rarely load-bearing — prefer a non-numeric/shorter id) or regenerate the snapshot with a non-colliding name; if it genuinely cannot be renamed AND the inventory does not need it, add it to `denylistGlobs` to exclude it at ingest. Do NOT relax or bypass the gate — a coincidental checksum is the accepted cost of a zero-false-negative PII control.

3. When the dry-run reports the steering and status paths with `ground: dry-run (nothing written)`, review what WOULD be written. The docs contain only identifiers, paths, and counts — never file contents:
   - `.brainiac/steering/tech.md` — languages, grounded-file count, out-of-scope notes (e.g. the C# subsystem deferred this phase).
   - `.brainiac/steering/structure.md` — per-file symbol names.
   - `.brainiac/steering/product.md` — classified endpoints and UI components.
   - `.brainiac/status.json` — epic ids, back-refs, checkbox rollup, integration branch.

## Phase 2 — write and advisory scan

1. Once the dry-run is clean and reviewed, write the artifacts and run the advisory repo scan:

   ```bash
   brainiac ground --root . --scan --repo-name <repo>
   ```

   On success brainiac prints the written steering paths, the status path, `ground: wrote artifacts`, and one gitleaks advisory line — exactly one of three, none of which affects the exit code:
   - `advisory: gitleaks found N potential secret(s) (non-blocking)` — the scan ran and counted findings.
   - `advisory: gitleaks not installed — recommend: brew install gitleaks` — the binary is absent.
   - `advisory: gitleaks scan failed (non-blocking): <summary>` — gitleaks ran but failed (config error / version skew / OOM). A failure is reported as such, never fabricated as a clean "found 0".

   On a RE-run where a prior `tech.md` was generated from a different HEAD, brainiac additionally prints one §15 staleness advisory (also non-blocking): on apply, `advisory: prior steering was stale (generated from a different HEAD) — regenerated with :ground`; on `--dry-run`, `advisory: prior steering is stale (generated from a different HEAD) — re-run without --dry-run to refresh`. A non-git/unborn-branch repo (no resolvable HEAD) does not emit it.

2. Confirm `.brainiac/` was written and that `.gitignore` now ignores `.brainiac/*` (the directory contents) while un-ignoring `.brainiac/status.json` (so the manifest is the one tracked artifact). Ignoring the contents with `.brainiac/*` — rather than the directory itself with `.brainiac/` — is what lets the `!.brainiac/status.json` negation take effect; git cannot re-include a file beneath a directory that is itself excluded.

## Batch — ground every reference repo at once

On the PM / brain side you usually want to ground **all** the cloned reference repos in one pass, not one at a time. From the brain repo root:

```bash
brainiac ground --all
```

This reuses the references catalog as the source of truth: it grounds every repo cloned under `.references/`, skips any catalog entry that is not cloned (reported, never grounded), and runs the same HARD per-repo PII gate — a halt on one repo is reported and the batch **continues** with the rest.

`--all` is **idempotent and stale-aware**: a repo whose steering still matches its current `HEAD` is left untouched (reported `fresh`), and only repos whose `HEAD` moved since they were grounded get re-grounded (reported `refreshed`). That makes **refresh and initial grounding the same command** — after a `brainiac references` pull moves some HEADs, just re-run `brainiac ground --all` and only what changed is re-grounded. There is no background re-grounder; refresh is this one explicit, operator-visible command.

Flags: `--only <csv>` (restrict to named repos), `--force` (re-ground even `fresh` repos), plus `--dry-run` and `--scan` (same meaning as the single-repo run). The command exits non-zero if any repo halted on the PII gate, so CI and the agent notice. Run it from the brain root — outside a brain checkout (no `.references/`) it refuses with a clear message.

## Notes

- The inventory uses an LSP language server (`typescript-language-server --stdio`) for the TypeScript adapter only. C#/.NET is deferred this phase and surfaces as an out-of-scope note rather than failing the run.
- If no TypeScript server is detected, brainiac still grounds: it records languages and out-of-scope notes with an empty symbol set.
- **Expect a few seconds of silence on the first inventory.** The first `ground` spawns `typescript-language-server`, which loads the project before answering — the CLI prints nothing for up to ~15s before output. This is normal startup, not a hang.
- **A wedged/crashed server degrades safely, it never blocks or throws.** If the steering output carries a note like `Symbol walk aborted after N file(s) — LSP server stopped responding … M remaining file(s) not inventoried`, the language server wedged or died mid-inventory. The inventory is partial-but-safe: the symbols collected so far are kept, the remaining files are counted as skipped, and the run still completes with exit 0. This is distinct from a clean "repo has no symbols" (no abort note, empty symbol set). Re-run `:ground` once the server is healthy to complete the inventory.
