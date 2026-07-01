# schnapp-os Streamline - Design Spec

**Date:** 2026-06-30. **Status:** design approved (brainstorm 042+), pre-implementation.
**Supersedes direction of:** decisions/0011 #2 (repo-flattening - now RESOLVED yes, see §4).
**Companion:** phased implementation plan (writing-plans, separate doc). This spec is WHAT + WHY; the plan is HOW + ORDER.

Write instruction files in the owner writing-style standard (§3.4). This spec follows a deviation of it.

## 1. Objective
Streamline schnapp-os and make it easier to understand WITHOUT sacrificing performance or capability. Reconsider everything against a refined target; keep-by-default, change only with cause.

**Priorities (revised, supersede master-instructions goal order):**
1. **ACCURATE**: grounded in verified captured knowledge with provenance. Top goal.
2. **FRESH**: accuracy's inseparable engine (no accuracy on stale data). Treat 1+2 as one.
3. **CONSISTENT**: one voice/format/quality bar everywhere.
4. **GLOBAL**: identical from any surface.
5. **QUICK**: lean always-load, fast retrieval.

Gap weighting: an accuracy/freshness gap outranks a global/quick gap.

## 2. Verified diagnosis (5-agent read-only audit, 2026-06-30)
**schnapp-os captures diligently, enforces selectively, and shelves knowledge in too many places.** Capture is NOT the problem; enforcement and fragmentation are.

- **Natural experiment (own history):** lessons that became a code/hook fix STOPPED recurring; lessons that became only prose KEEP recurring (malformed-secret bytes ≥4 sessions, stale-plugin-pin ≥3). Enforcement stops recurrence; documentation does not.
- **Enforcement skew (B):** only ~3/7 hooks enforce, all shell/secret hygiene. The cardinal epistemic/state rules map to no blockable event.
- **Fragmentation (C,D):** durable knowledge smeared across 5+ stores (`memory/`, `decisions/`, `handoffs/`, `PROGRESS.md`, Obsidian vault, memory-mcp). Even canonical `memory/` has 3 frontmatter schemas, a DEAD supersede-check, and 7/8 facts missing `updated:`.
- **Bloat is orthogonal (A):** always-load layer is lean (~220 lines) - KEEP. Bloat lives in the reference layer (`PLAN.md` 677, docs→1292, 43 handoffs) that agents pull but don't read fully.
- **Packaging is dead weight (E):** native `.claude/` discovery + `settings.json` hooks already replace the plugin+marketplace.

**Redesign principle:** MOVE LOAD-BEARING KNOWLEDGE FROM SHELF TO GATE. One canonical store + deterministic enforcement at the moment of action.

## 3. Domain 1 - Source of Truth

### 3.1 Topology
- **Git is the ONE truth.** No store outside git is canonical - durability, portability, audit come from git.

### 3.2 Two-repo split on the ATOMICITY line
- **Rule:** anything that MUST commit atomically with a system change stays with the system - you cannot make one atomic commit across two repos, and atomicity is what prevents staleness.
- **`schnapp-os`** = system + system-state: rules, skills, hooks, commands, agents, `PLAN.md`, `PROGRESS.md`, `decisions/`, `handoffs/`, CATALOG.
- **`schnapp-vault`** = cross-surface knowledge with no commit-coupling: the memory lane + second-brain (`areas`, `knowledge/wiki`, `reviews`).

### 3.3 The vault repo: `schnapp-vault`
- **GitHub:** PRIVATE (holds credential-state + personal knowledge), same account as schnapp-os.
- **Local:** `~/code/schnapp-vault`, sibling to `~/code/schnapp-os`. This folder IS the Obsidian vault (open directly).
- **OUT of OneDrive**: a git working tree inside OneDrive corrupts (`.git/` raced by two sync engines). Git provides versioning + backup + sync; OneDrive's role for the vault is redundant → drop it. ONE sync engine.
- `memory-mcp` and `obsidian-mcp` repoint to `~/code/schnapp-vault`. Optional `~/Documents/Obsidian` symlink → here.
- **End state:** ONE vault. Collapses `memory/` + OneDrive-Obsidian + memory-mcp-backing into a single store (5+ knowledge homes → 2).

### 3.4 Vault structure + behavior boundary
- **Behavior stays with the system.** skills/rules/hooks/commands/agents = schnapp-os (executed by the harness, the shareable-later layer). Vault = KNOWLEDGE only. (Overrides master-instructions' put-skills-in-vault - mixing behavior into the knowledge store re-creates the coupling we split.)
- **Vault `agents.md` = NARROW** self-describing contract: the schema, supersede rule, capture-here, area rules. It owns vault-conventions; schnapp-os owns system-behavior; no overlap. Needed so a hookless surface can read/write the vault WITHOUT schnapp-os loaded.
- Layout:
```
~/code/schnapp-vault/
  agents.md   index.md   README.md
  /memory     MEMORY.md + <fact>.md (flat, one fact/file)
  /areas      /work /personal /_adhoc
  /knowledge  /raw /raw/processed /wiki
  /reviews
```
- `/memory` stays the existing FLAT one-fact-per-file lane (keep-by-default). Whether to adopt tiered working/episodic/semantic memory is DEFERRED (§12) - the flat lane stays until a loop redesign justifies it.

### 3.5 Provenance schema (fixes the live drift bug)
- ONE schema, FLAT (nested caused the dead check - flat keys are deterministically parseable), MINIMAL (every field earns its place via recall-use OR gate-enforcement).
```
---
name: <kebab-slug>          # identity; matches filename; [[name]] links resolve here
description: <one line>      # recall relevance
type: user | feedback | project | reference
area: work | personal | global
source: <session-id | file | url>    # provenance - accuracy #1
created: YYYY-MM-DD          # ISO 8601
updated: YYYY-MM-DD          # freshness; bump on every edit
superseded: false            # true only when the whole file retires for a successor
---
```
- **Single definition site = vault `agents.md`.** CI gate ENFORCES; `README.md` + memory-write instructions REFERENCE, never restate. (3 schema-truth sources → 1 = the actual anti-drift fix.)
- **Supersede, reconciled with git:** default when a fact changes = overwrite in place + bump `updated:` (git history = audit trail, no contradicting copy lingers). `superseded: true` only retires a whole file toward a `[[successor]]`; a prune job clears it later.

### 3.6 Enforcement point (not a single write path)
- Cowork's memory-mcp reach is UNVERIFIED, so correctness does NOT hang on one write path. Instead: ONE enforcement POINT every path funnels through = the **vault CI push-gate** (surface-independent; the `freshness.yml` pattern). Blocks bad schema / missing `updated:` / orphan-supersede regardless of writer.
- `memory-mcp` validates-on-write as the front-line where reachable; the GitHub connector stays Cowork's writer (CI catches its mistakes).

## 4. Domain 2 - Enforcement + Improvement

### 4.1 The ladder (weak → strong)
1. Advisory rule (read-gated) · 2. Memory fact (recall-gated) · 3. Deterministic Code hook (Code-only) · 4. Surface-independent CI gate (ALL surfaces).
- CI (rung 4) is strongest - the only gate hookless surfaces cannot route around.

### 4.2 Escalation policy - RECURRENCE is the trigger, not severity
- New lesson starts rung 1-2. Same class recurs (≥2) → escalate to a gate.
- Deterministic (a mechanical check exists) → gate, CI-first, hook for speed.
- Judgment (verify-before-asserting, generalize-the-fix) → NO fake gate; keep on the lean always-load shelf (it DOES load) + optional Code point-of-action nudge.
- **Discipline:** do not gate what has not recurred. Would a staff engineer call this gate justified by evidence?

### 4.3 Applied to the open classes
- **malformed-secret bytes** (≥4) → deterministic byte-check gate (`op read | xxd` at rotate/store); `rotate-secret` grows a verify step.
- **stale-plugin-pin** (≥3) → caused BY the plugin packaging; §5 flatten DELETES the class. No new gate.
- **prose-doc staleness** → keep `freshness.yml`; extend `last-verified` where deterministic; residual is judgment (advisory).
- **tracker-currency / verify / generalize** → NOT recurred → stay advisory.

### 4.4 Loop rewire (the compounding fix)
- The nightly worker counts error-class frequency. On a repeat (≥2 same class) it emits a **drafted gate** (a check, as a PR/issue for owner approval) instead of another prose fact. Learning compounds into ENFORCEMENT, not documentation.

## 5. Domain 3 - Context / Reference Discipline
- Root cause = reference-layer bloat, NOT always-load (lean, untouched).
- **Adopt the owner writing-style standard as a schnapp-os rule** (`rules/global/`) - instruction files terse-imperative; deviation elsewhere. The primary anti-bloat lever; keeps files short enough to be read whole.
- **Reconcile `PLAN.md` (677)** the way `PROGRESS.md` went 1281→104 (ADR-0022 precedent): archive completed phases, keep active work live, set a rotation policy.
- **Soft length-advisory** (WARN, not block - length is heuristic) on always-load + rules files.
- **Handoffs** stay append-only history; newest = resume; light-archive the rest + thin index.
- Reference navigability = pointer-index-first (CATALOG / `index.md`) so agents pull the right slice, not the whole file.

## 6. Domain 4 - Capability + Packaging
- **FLATTEN the plugin → native `.claude/`.** Resolves decisions/0011 #2. Packaging is dead weight; native discovery replaces it; moots the double-load bug AND the stale-plugin-pin class; a single owner needs no marketplace distribution.
- **Defer generic skills** to installed plugins: `grill-me`→`superpowers:brainstorming`; `/do` plan-branch→superpowers/ce planning; thin `performance-optimizer`→`ce-performance-oracle`. KEEP `grill-with-docs` (unique: updates repo docs inline).
- **Keep every owner-domain skill** (SQL/ETL/AppFolio/Quickbase, secrets, status/surface/session, memory-routing) - no plugin equivalent.
- **Namespace collision:** `anthropic-skills` ships `surface-check` + `session-hygiene`; verify precedence at build, rename owner's if it loses.

## 7. Domain 5 - Cowork Two-Way Handoff
- Shared truth = the two git repos. Handoff rides git, not a bespoke channel.
- **Protocol (surface-independent):** whoever stops writes a handoff packet (newest handoff + working-memory + `index.md`) → pushes (Code: native git; Cowork: GitHub connector) → the other pulls on start and resumes. Unifies the hookless `session-hygiene` ritual with the Code hooks - same packet, different transport.
- Built on the lowest CONFIRMED-working path → needs zero unverified Cowork capability. Validated memory-mcp writes are an optional UPGRADE pending the probe (§10).

## 8. Change surface (high-level; per-file steps → plan)
- **Create** `schnapp-vault` (repo + local + Obsidian + MCP repoint + OneDrive exit).
- **Migrate** `schnapp-os/memory/` → `schnapp-vault/memory/`; normalize all facts to §3.5 schema; add missing `updated:`.
- **Flatten** `plugins/core/{skills,commands,agents,rules,scripts,hooks}` → native `.claude/` + top-level; delete `marketplace.json` + `plugin.json`; uninstall cached plugin; retarget ~20 live docs + `settings.json` hook paths.
- **Gates:** vault CI (schema/updated/supersede - FIX the dead check against the flat key); malformed-secret byte-check; loop-rewire (recurrence→drafted gate).
- **Rules:** add writing-style rule; reconcile `PLAN.md`; add length-advisory.
- **Repoint** `memory-mcp` + `obsidian-mcp` at the vault; keep connector as Cowork writer.

## 9. Owner action items
1. **Flatten build-step:** one-line `~/.claude/CLAUDE.md` `@import`-path edit PER MACHINE (outside the repo). Exact line supplied at that step.
2. **Cowork probe** (optional, non-blocking): confirm whether Cowork reaches `memory-mcp` / `.mcp.json` servers → upgrades write-validation only.
3. **brain-capture prune** (known): remove the dead claude.ai connector.

## 10. Open contingencies
- Cowork memory-mcp reachability (§9.2) - design works without it; probe only upgrades front-line validation.
- Vault↔schnapp-os cross-references (a handoff cites a decision cites a memory fact) - the plan must keep links resolvable across the split.

## 11. ADRs to write at build
- Two-repo split on the atomicity line; git = one truth; vault out of OneDrive.
- Enforcement ladder + recurrence-escalation policy.
- Flatten plugin → native `.claude/` (supersedes/executes 0011 #2).
- One flat memory schema, defined in vault `agents.md`, CI-enforced.

## 12. Non-goals
- NOT a ground-up rebuild - keep-by-default, change with cause.
- NOT building the sharing surface - keep the seam clean, defer.
- NOT adopting master-instructions wholesale - accuracy-first reorder, behavior stays in schnapp-os, tiered memory deferred.
- NOT gating judgment rules or un-recurred classes.
