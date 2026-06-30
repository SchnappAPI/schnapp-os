# Schnapp-OS Framework

The design framework for the system. Two halves that mirror each other: the **principles** the
system is built on, and the **issues it exists to prevent**. Every principle traces to a real
failure; every failure is generalized to its class, not the one instance that exposed it.

This document states design intent only. It hardcodes no mutable facts (status lives in
[PLAN.md](../PLAN.md) / [PROGRESS.md](../PROGRESS.md), rules in
[plugins/core/rules/](../plugins/core/rules/), decisions in [decisions/](../decisions/)). It
references those; it does not copy them.

---

## 0. Purpose

One Claude system, used across every surface (Code on all machines, Cowork, claude.ai, iPhone).
**One source of truth. No duplication. Nothing siloed. References to secrets, never values.**
The system should let work resume seamlessly on any surface, stay honest about its own state, and
run unattended without quietly rotting or quietly dying.

---

## 1. Design principles (the directions)

### A. Single source of truth
- One fact lives in **one** canonical file. Everywhere else imports it or references it by path.
- A document never hardcodes a mutable fact it does not own. It points at the owner.
- **Current-state only.** When something changes, overwrite it. No struck-through values, no
  "deprecated" markers, no status frozen into prose.
- Generated artifacts (e.g. `CATALOG.md`) are regenerated, never hand-edited.

### B. Anti-staleness
- Every state-changing commit updates its tracker (flip the PLAN box, append the PROGRESS line) in
  the **same commit**, and pushes immediately so GitHub mirrors local.
- **Supersede, do not append.** When a fact changes, replace it. Never leave a contradicting copy.
- **Fix the class, not the instance.** A correction sweeps every sibling of its kind in the same
  pass and routes the lesson to a rule, memory, or doc fix.
- Freshness is enforced, not hoped for: a CI gate fails the push when a generated doc is stale or a
  `last-verified` doc's source changed after it.

### C. Working style (agent behavior)
- Direct. Lead with the recommendation, then the why. Terse but complete. No fluff, no em dashes.
- **Never guess.** If a fact, file, flag, table, or capability is uncertain, verify it first or say
  so. "I am not certain" beats a confident wrong answer.
- **Verify before asserting.** Read a file before editing it; grep for callers before changing a
  function; confirm a thing exists before claiming it does.
- **Think in systems, not instances.** Trace what every change touches (docs, trackers, surfaces,
  dependents, the install path) and update all of it in the same change.
- **Work from the objective, not the literal ask.** Surface the risks and gaps you were not told
  about. Catching what the instruction left out is the job.
- **Fix defects on sight, in the same turn.** A defect is not a decision. Do not park it, defer it,
  or sit on it. The only exception is a fix needing access you lack: hand over the exact command.
- **Record failed approaches before retrying.** An undocumented failure gets walked into again.
- Production-ready by default. Verify before claiming done.

### D. Secrets and security
- **Secrets are references, never values.** No secret value ever enters a tracked file. Store the
  `op://vault/item/field` URI or which connector serves it.
- New env vars appear in `.env.template` as `op://` URIs, never literals.
- Spot a hardcoded credential: stop and flag it.
- Privileged production access is **authorized, not standing in the clear**: Mac mutation tools run
  via transport-level bearer auth that never enters a transcript; read-only introspection is the
  default.

### E. Git and change flow
- **Main only.** No feature branches, no PRs for directed work, on every surface including web.
  Run tests and a local review pass, then push; CI runs on the push.
- **Autonomous self-edits are gated, not branched.** A pre-commit gate (approve/hold) filters
  machine-generated edits; held proposals surface as issues. Judgment-bearing self-edits stay
  reviewable so a learning loop cannot land confident junk.
- Standing authority: the agent acts without per-action confirmation and auto-merges green
  engineering work. The gate, not a human click, is the safety net.

### F. Automation and loops
- **Loops before features.** Prove the recurring routine works before adding new capability on top.
- **Safe vs asks-first.** Read-only routines run unattended and report. Mutating routines (running a
  backup, deleting, rotating) queue a proposal for approval. Never silently mutate.
- **Automate; do, don't tell.** Run the command, read the output, proceed. Surface only the
  genuinely owner-only step (1Password admin mint, third-party console regen).

### G. Access and environment
- **Never-blocked model:** a blocked host means add it to the environment network allowlist (one
  canonical list), not work around it. A missing host makes tools silently absent, not error loudly.
- Git-write path is defined and ordered: writable token, then Mac shell, then GitHub MCP API. The
  cloud session's own git remote is read-only.
- Hookless surfaces resolve any action in order: native here, then remote MCP, then generate a
  ready-to-run prompt for a Code session.

### H. Capability design
- **Small, single-purpose, reusable skills**, never monoliths.
- **Skill-ify repetition.** Anything done repeatedly becomes a skill.
- **Parallelize.** Independent work fans out to subagents to cut wall-clock.
- Build only capability that serves the actual platform; defer the rest.

### I. Knowledge and handoffs
- Personal notes, preferences, and temporary context go to **memory**, not project files. General
  lessons to the global lane; project facts to the project lane.
- Ask before creating a new top-level document.
- A handoff is both a copy-paste primer for a fresh session **and** a written file packing the
  context needed to resume seamlessly.

---

## 2. Issues I am trying to avoid

The failure classes the framework above exists to prevent. Each is the hazard, generalized; the
parenthetical is the real incident that proved it.

### Drift and staleness
- **A fact going out of date in one place while a copy lives on elsewhere** (docs hardcoding mutable
  status; 3 memory files stale again this session).
- **A generated artifact diverging from its source** (`CATALOG.md` not regenerated after a rule edit).
- **A correction fixed only where it was spotted**, leaving identical siblings broken.
- **Append-instead-of-supersede**, leaving two contradicting versions of the same fact.

### Duplication and siloing
- **The same knowledge captured in two places**, so the two drift apart.
- **A surface holding its own private copy** of something that should be one source.

### Secret leakage
- **A secret value written into any tracked file** (the 2026-06-17 plaintext dump: GitHub PATs,
  Anthropic key, OAuth, MCP bearers, DB and Web App secrets across ~28 vault export files, private
  but pushed and OneDrive-synced).
- **Relocating a burned secret instead of rotating it** (the 2026-06-26 flatten copied leaked values
  rather than minting fresh ones).
- **A secret transiting a session transcript** during a file dump (redaction gaps).

### Silent automation death (the largest current gap)
- **A scheduled job that stops and tells no one** (SQL backup dead ~2 months; the only watchdog is a
  health probe nobody is paged by).
- **An install that "succeeds" but leaves a dead job** (LaunchAgent absent or not loaded after a
  supposed install).
- **A monitoring probe that lies** (DB reported unreachable because the probe's own client library is
  missing, masking whether the database is actually healthy).
- **A config rotation that doesn't propagate** (old launchd services cache a rotated token in-process
  until restarted; env not refreshed; Render not redeployed).

### Lossy operations
- **A blind overwrite destroying unselected content** (`write_file` truncates the whole file; used on
  PROGRESS.md mid-session without append).
- **Superseding a memory fact without a reason**, losing information the old version held.

### Confident-wrong and unverified
- **Asserting a file, flag, table, or capability exists without confirming it.**
- **Presenting a guess as fact** instead of flagging uncertainty.
- **Re-walking a failed approach** because the prior failure was never recorded.

### Fragile coupling
- **A value not matching the shape its parser expects** (quoting the SA token broke all 6 services:
  `op-wrap` greps and strips the line literally, so the quotes became part of the value).
- **A tool's hidden behavior assumed away** (`shell_exec` strips the 1Password identity, so `op`
  calls fail unless routed through `op_run`).

### Stale snapshots and pinned state
- **A pinned plugin commit firing old bundled hooks** after the source moved, racing the live gate.
- **Name-based uninstall removing the wrong duplicate** when two marketplaces install the same plugin.
- **Hook edits not taking effect** because a snapshot only re-reads on re-pin, not immediately.

### Access surprises
- **A missing allowlist host making tools silently absent** (403 on CONNECT, not a loud error).
- **Assuming the cloud session can push** (its git remote is read-only; writes route via the Mac).
- **Assuming hooks ran** on a surface that may be hookless (treat as hookless until verified).

### Sprawl and residue
- **Per-session branches accumulating** when sessions die without merging (14 stray branches swept).
- **Capability built ahead of need**, adding surface area before the loops under it are proven.

---

## 3. The throughline

The system's two enemies are **silent drift** (things quietly going out of date) and **silent
stop** (automation quietly dying). The framework is strong against the first: canonical sources,
supersede-not-append, freshness CI, current-state-only docs. It is weaker against the second, but no longer blind to it: the infra-health probe now **pages off-Mac
on a RED** (`notify-ops.sh` to ntfy) for a missing agent, a stale backup, or a down service, so a silent
stop alarms instead of sitting undetected. Two edges remain: the probe only fires if it *itself* stays
scheduled (an external dead-man's-switch is the deeper guard), and a probe that fails for the wrong reason
still has to be told apart from a true RED.
