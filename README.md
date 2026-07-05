# brainiac

The **developer surface** of brainiac — install the develop pipeline plus the shared governance
gates with **no private-repo access, no npm, no PAT**. You get a prebuilt `brainiac` CLI for
your platform and the `brainiac` plugin (Claude Code / Copilot CLI), which auto-installs
**superpowers** as a dependency so TDD, debugging, code review, and verification all light up
in a single command.

> Generated from `inewi/brainiac-pipeline` by `npm run build:dev-plugin`. Do not edit by hand.

## Quick install

**macOS / Linux:**

```sh
curl -fsSL https://raw.githubusercontent.com/inewi/brainiac-dist/main/install.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/inewi/brainiac-dist/main/install.ps1 | iex
```

Installs the prebuilt `brainiac` CLI for macOS (arm64/x64), Linux (x64/arm64), and Windows (x64)
into `~/.local/bin` (`%USERPROFILE%\.local\bin` on Windows), then runs `brainiac setup --dev`
to wire the `brainiac` plugin + superpowers on each detected host (Claude Code or Copilot
CLI). No inewi access required.

On macOS/Linux, pass `-s -- --no-setup` to install the CLI only, or `-s -- --bin-dir <path>` to
change the install location. On Windows, download `install.ps1` and run it with `-NoSetup` /
`-BinDir <path>` (piping to `iex` can't forward parameters).

### Plugin only (manual)

If you already have the `brainiac` CLI, or want to install the plugin by hand:

```sh
# Claude Code — superpowers auto-installs as a dependency (claude-plugins-official is built-in)
claude plugin marketplace add inewi/brainiac-dist
claude plugin install brainiac@inewi

# Copilot CLI — superpowers resolves from a different marketplace, so add it explicitly
copilot plugin marketplace add inewi/brainiac-dist
copilot plugin install brainiac@inewi
copilot plugin marketplace add obra/superpowers-marketplace
copilot plugin install superpowers@superpowers-marketplace
```

## How it works

brainiac is the **conductor** — it owns the dev pipeline skeleton and tells Claude
WHEN to use superpowers and WITH WHAT context. It does not replace superpowers. It
delegates.

```
┌──────────────────────────────────────────────────────┐
│                brainiac (governance)                 │
│                                                      │
│  /brainiac:develop    enter epic branch → next task  │
│                       → TDD → verify → push-per-task │
│                       → finalize the epic            │
│  brainiac check       pre-commit hook gate           │
│                                                      │
│  brainiac delegates to:                              │
│    └─ superpowers  → HOW to build (TDD, debug,       │
│                       review, verify)                │
└──────────────────────────────────────────────────────┘
```

| brainiac provides | superpowers provides |
|---|---|
| WHAT to build | HOW to build it |
| Spec-driven governance | TDD discipline |
| Cross-repo contracts | Systematic debugging |
| Freshness + drift gates | Code review process |
| Artifact governance (ONE WAY) | Verification before merge |
| Pre-commit enforcement gate | Branch management |

## What's included

### Commands (Claude Code slash-commands)

| Command | What it does |
|---|---|
| `/brainiac:develop` | Full dev session, git-native from the first step: enter an epic branch → next unblocked task → TDD → push-per-task → finalize the epic |
| `/brainiac:analyze` | Cross-artifact traceability + symbol-resolution gate for a spec |
| `/brainiac:clarify` | Resolve `[NEEDS-CLARIFICATION]` markers in a spec |
| `/brainiac:contract` | Show the API/schema/interface a task promises to expose |
| `/brainiac:debug` | Systematic debugging with brainiac-aware context |
| `/brainiac:grill` | Relentlessly stress-test an authored design before build (task, epic, or spec) |
| `/brainiac:grill-me` | Free-form, anytime grill — stress-test any idea mid-conversation, writes nothing |
| `/brainiac:ground` | Inventory the repo + provision PII-free steering docs |
| `/brainiac:handoff` | Grade harness, install gate, publish status, bootstrap TDD |
| `/brainiac:init` | Provision the brainiac convention — dry-run first |
| `/brainiac:migrate` | Roll provisioned repos forward to current convention version |
| `/brainiac:plan` | Validate + foundations-first phase a spec's tasks.md graph |
| `/brainiac:quick` | Escape hatch — skips ceremony, keeps TDD/verification/gates |
| `/brainiac:reconcile` | Read-only drift: live tasks.md vs published status.json |
| `/brainiac:reflect` | Review captured friction, surface evidence-ranked suggestions |
| `/brainiac:sequencer` | Detect dangling cross-repo edges + inject contract-consumer edges |
| `/brainiac:specify` | Scaffold a spec the ONE WAY into specs/EPIC-####-slug/ |
| `/brainiac:status` | Cross-repo task dashboard — reads status.json across repos |
| `/brainiac:tasks` | Validate the cross-repo task graph for an epic |

### CLI verbs (terminal)

```
brainiac                bare in a real terminal: the interactive TUI cockpit (also: dash | tui)
brainiac develop        --list enumerates epic branches + readiness; enter --epic starts one
brainiac check          run the pre-commit gate (paths + secrets; --spec / --freshness opt-in)
brainiac ground         inventory the repo + provision steering/status
brainiac specify        scaffold a spec the ONE WAY
brainiac plan           validate + phase the tasks.md graph
brainiac analyze        read-only cross-artifact + symbol-resolution gate
brainiac status         read-only cross-repo rollup (--json for the cockpit feed)
brainiac reconcile      read-only drift: live tasks.md vs published status.json
brainiac handoff        grade harness + install gate + publish status + bootstrap
brainiac init           show the convention-provisioning plan (dry-run)
brainiac install-hooks  install the pre-commit + pre-push gates
brainiac migrate        roll provisioned repos forward to the current convention version
brainiac reflect        self-reflection loop (suggest-only, never auto-applies)
brainiac sequencer      detect dangling cross-repo edges + inject contract-consumer edges
brainiac setup          wire the marketplace + companion plugins on each host
brainiac --version      print version and exit
```

### Background skills (loaded automatically by Claude Code)

- **conventions** — ONE WAY spec format, EARS notation, EPIC IDs, naming invariants
- **cognitive-steering** — structured thinking patterns for planning, analyzing, and deciding
- **cross-repo-governance** — the full pipeline with superpowers delegation at each phase
- **grill** — the relentless design stress-test behind `/brainiac:grill` and `/brainiac:grill-me`
- **guardrails** — pre-flight safety checks that catch dependency gaps, contract violations,
  and spec drift before they become rework

### Agents (Copilot CLI)

- **brainiac-develop** — the dev pipeline
- **brainiac** — generalist: routes any verb to its CLI command or the right skill

## Requirements

- **Claude Code** v2.1.110 or later, or **GitHub Copilot CLI**
- **git** — grounding, handoff, and the check gate use git
- **universal-ctags** (optional) — Swift symbol extraction only; if absent, `.swift` files
  are skipped with a clear advisory
- **macOS, Linux, or Windows** — macOS/Linux arm64 or x64; Windows x64 (also runs on
  Windows-on-ARM via x64 emulation) — the prebuilt binary platforms

## Your first /brainiac:develop session

```sh
# 1. Ground the repo (inventory it so brainiac knows what's there)
brainiac ground --root . --repo-name my-repo --scan

# 2. Scaffold a spec (or use an existing one from the PM pipeline)
brainiac specify "Add CSV Export" --repo . --brain-root .

# 3. Start the dev pipeline
/brainiac:develop
```

In Copilot CLI, invoke the `brainiac-develop` agent instead of the slash-command — same
pipeline, different surface.

## Superpowers

brainiac **depends on** superpowers. On Claude Code it auto-installs (the
`claude-plugins-official` marketplace is built-in). On Copilot CLI, `brainiac setup --dev`
(or the manual commands above) installs it explicitly — same result either way.

## How it's built

brainiac is **generated** from the canonical `brainiac` plugin by `npm run build:dev-plugin`
(`src/plugin-split/generate-dev-plugin.ts`). It copies every dev-safe command, skill, and agent
(= everything not in the PM-only partition), writes a `dependencies`-declaring manifest with
the cross-marketplace `allowCrossMarketplaceDependenciesOn` allowlist, and refuses to publish
if any emitted file leaks internal knowledge. The source repo is private; this dist repo is
public — that's the whole point.
