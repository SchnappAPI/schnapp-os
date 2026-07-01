# schnapp-os Streamline — Implementation Plan (phased)

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement each phase task-by-task. Steps use checkbox (`- [ ]`) syntax. **Phase 1 is detailed to task level; Phases 2–5 are task outlines — generate their step-level bite-sized detail (with exact code) at the start of that phase, when the code specifics are stable.**

**Goal:** Streamline schnapp-os per [the design spec](../specs/2026-06-30-schnapp-os-streamline-design.md) — one canonical source of truth, enforcement moved from shelf to gate, plugin flattened — without sacrificing capability.

**Architecture:** Two git repos split on the atomicity line: `schnapp-os` (system + system-state) and a new `schnapp-vault` (cross-surface knowledge, = the Obsidian vault). Enforcement funnels through surface-independent CI gates. Native `.claude/` discovery replaces the plugin.

**Tech Stack:** git + GitHub (private), bash hooks + GitHub Actions CI, Python (learning worker), 1Password `op` CLI, memory-mcp + obsidian-mcp (MCP servers), Obsidian.

## Global Constraints (verbatim, apply to every task)
- **Git = the one truth.** Nothing canonical lives outside git.
- **main-only, commit + push every change**; pull `--rebase --autostash` before push; never branch unless told; destructive ops need owner approval.
- **Secrets are `op://` references, never values.** New env vars → `.env.template` as `op://` URIs.
- **Instruction files** (`CLAUDE.md`, `agents.md`, rules) → the writing-style standard; everything else a deviation.
- **ISO 8601 dates** in filenames; spell names out; no force-push.
- **Keep-by-default** — change only with cause; this is not a rebuild.

## Phase sequencing (dependencies)
```
Phase 1 (vault) ──┬─> Phase 3 (gates)   [needs vault CI + flatten]
                  ├─> Phase 5 (Cowork)  [needs vault as shared store]
Phase 2 (flatten)─┘
Phase 4 (context discipline) — independent, run any time
```
Recommended order: **1 → (2 ∥ 4) → 3 → 5.** Each phase ends shippable.

---

## Phase 1 — Vault stand-up
**Deliverable:** `schnapp-vault` exists (private, local, = Obsidian vault), `memory/` migrated + schema-normalized, vault CI gate live (dead supersede-check FIXED), MCPs repointed.

**Owner-action gates in this phase (hard-to-reverse — confirm before running):**
- Create the GitHub repo (owner account).
- Move the Obsidian vault out of OneDrive (owner filesystem + OneDrive state).
- Repoint `memory-mcp` + `obsidian-mcp` (running services).

**Files:**
- Create: `~/code/schnapp-vault/{agents.md, index.md, README.md, .github/workflows/vault-freshness.yml, scripts/check-frontmatter.sh}`
- Move: `schnapp-os/memory/*` → `~/code/schnapp-vault/memory/`
- Modify: `schnapp-os` references to `memory/` (CLAUDE.md, README, session-hygiene, memory-mcp/obsidian-mcp config)

**Tasks:**
1. **Create `schnapp-vault` repo** — `gh repo create <owner>/schnapp-vault --private`; clone to `~/code/schnapp-vault`. Verify: `git -C ~/code/schnapp-vault rev-parse --show-toplevel`. *(owner-confirm)*
2. **Author `agents.md`** — the narrow vault contract: the §3.5 flat schema (single definition site), supersede rule, capture-here, area rules, `/memory /areas /knowledge /reviews` layout. Verify: a human read + it names every schema field.
3. **Migrate `memory/`** — `git mv` each fact from schnapp-os into the vault; scaffold `/areas/{work,personal,_adhoc}`, `/knowledge/{raw,raw/processed,wiki}`, `/reviews`. Verify: fact count matches; MEMORY.md index regenerated.
4. **Normalize every fact to the one schema** — convert nested `metadata:` → flat keys; add missing `updated:` (= file's last git-commit date); set `source:`, `superseded: false`. Verify: `check-frontmatter.sh` passes on all facts.
5. **Write `check-frontmatter.sh`** (TDD) — fails on: nested `metadata:`, missing any required flat key, missing `updated:`, orphan `superseded: true` with no `[[successor]]`. This FIXES the dead check (greps the flat top-level key, not an indented one). Test with fixtures (good + each bad case) before wiring.
6. **Wire `vault-freshness.yml`** — runs `check-frontmatter.sh` on push/PR; blocks on failure. Verify: a deliberately-bad fact fails CI; a good tree passes.
7. **Exit OneDrive** — make `~/code/schnapp-vault` the canonical Obsidian vault; retire the OneDrive copy from the write path; open the folder in Obsidian. Verify: Obsidian reads it; `~/code/schnapp-vault/.git` is NOT under any cloud-sync path. *(owner-confirm)*
8. **Repoint MCPs** — `memory-mcp` + `obsidian-mcp` point at `~/code/schnapp-vault` (or its GitHub repo). Verify: `memory_read`/`memory_list` return vault facts; `obsidian` tools read the same tree. *(owner-confirm)*
9. **Update schnapp-os references** — CLAUDE.md, README, `session-hygiene`, backup script stop pointing at `schnapp-os/memory/`; point at the vault. Verify: freshness CI green; grep finds no live `schnapp-os/memory/` references.
10. **Write ADR** — two-repo split + git=one-truth + vault-out-of-OneDrive. Flip PLAN/PROGRESS. Commit + push both repos.

**Done when:** vault CI green, all facts one-schema, MCPs serve the vault, schnapp-os no longer owns `memory/`.

---

## Phase 2 — Flatten the plugin
**Deliverable:** native `.claude/` layout; marketplace + plugin.json gone; all references retargeted; hooks still fire.

**Owner-action gate:** one-line `~/.claude/CLAUDE.md` `@import`-path edit PER MACHINE (supplied exact); uninstall cached plugin locally.

**Tasks (outline — detail at execution):**
1. Move `plugins/core/{skills,commands,agents}` → `.claude/{skills,commands,agents}`; verify native discovery lists all 23 skills / 3 commands / 3 agents.
2. Move `plugins/core/{rules,scripts,hooks}` → top-level `rules/ scripts/ hooks/`; update `.claude/settings.json` hook paths; verify each hook fires (force-push guard, secret-scan, shellcheck, Stop push-gate, SessionStart/End).
3. Delete `.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`; uninstall cached `schnapp-os-core@schnapp-os`. *(owner: per-machine)*
4. Retarget the ~20 live docs + `gen-catalog.sh` + 2 CI workflows off `plugins/core/` paths; leave ~40 historical `handoffs/`/`decisions/` untouched (they describe the past).
5. Verify the `schnapp-os-core` double-load is gone (§ from substrate review). ADR (executes 0011 #2); flip trackers; push.

**Done when:** no plugin/marketplace remains, native discovery + hooks verified, freshness CI green, double-load resolved.

---

## Phase 3 — Enforcement gates
**Deliverable:** the recurring deterministic classes are gated; the learning loop emits gates.

**Tasks (outline — detail at execution):**
1. **Malformed-secret byte-check** (TDD) — a gate in the rotate/store path: `op read <ref> | head -c N | xxd` compares stored bytes to expected; fails on whitespace/quote/truncation. `rotate-secret` grows a verify step. Test with a deliberately-quoted/truncated fixture.
2. **Loop rewire** — `learning-worker` counts error-class frequency; on ≥2 same-class it drafts a gate (a check) as a PR/issue for approval instead of another prose fact. Verify with a seeded repeat class.
3. **Extend `last-verified`** coverage to more deterministic docs in `freshness.yml`.
4. ADR (enforcement ladder + recurrence-escalation). Trackers; push.

**Done when:** malformed-secret is gated + tested; a seeded repeat class produces a drafted-gate PR, not a note.

---

## Phase 4 — Context / reference discipline
**Deliverable:** anti-bloat rule in force; `PLAN.md` reconciled; length-advisory live.

**Tasks (outline — detail at execution):**
1. Add the writing-style standard as `rules/global/writing-style.md`; add to the `~/.claude/CLAUDE.md` `@import` list + `templates/user-global-CLAUDE.md`.
2. Reconcile `PLAN.md` (677) — archive completed phases to `docs/archive/`, keep active live, record a rotation policy (mirror ADR-0022). Verify: `PLAN.md` < ~150 lines, no active work lost.
3. Add a soft length-advisory (WARN, exit 0) over always-load + rules files; wire as a PostToolUse or CI advisory.
4. Light-archive old `handoffs/`; add a thin index. Trackers; push.

**Done when:** writing-style rule loads globally, `PLAN.md` trimmed with policy, length-advisory warns on an over-long fixture.

---

## Phase 5 — Cowork two-way handoff
**Deliverable:** Code ↔ Cowork hand off through the shared git repos.

**Tasks (outline — detail at execution):**
1. Ensure the GitHub connector has `schnapp-vault` access (Cowork's vault read/write path — the vault is not a plugin, so no auto-sync). Verify: a Cowork session reads a vault fact + writes one via the connector.
2. Define the handoff-packet convention (newest handoff + working-memory + `index.md`) both surfaces read on start / write on stop; fold into `session-hygiene`.
3. *(optional, owner probe)* Confirm whether Cowork reaches `memory-mcp` / `.mcp.json` servers → if yes, add validated-writes as the front-line.
4. Round-trip test: start work in Code → stop → resume in Cowork → stop → resume in Code, no lost state. ADR; trackers; push.

**Done when:** a Code→Cowork→Code round-trip preserves state end-to-end.

---

## Owner action items (consolidated)
1. **Phase 1:** confirm repo creation, OneDrive exit, MCP repoint.
2. **Phase 2:** per-machine `~/.claude/CLAUDE.md` `@import` edit; uninstall cached plugin.
3. **Phase 5:** connector vault access; optional Cowork memory-mcp probe.
4. **Anytime:** prune the dead `brain-capture` claude.ai connector.

## Self-review — spec coverage
- Spec §3 (source of truth) → Phase 1. ✓
- Spec §4 (enforcement) → Phase 3 + Phase 1 CI. ✓
- Spec §5 (context discipline) → Phase 4. ✓
- Spec §6 (capability/flatten) → Phase 2. ✓
- Spec §7 (Cowork) → Phase 5. ✓
- Spec §3.5 schema / dead-check fix → Phase 1 tasks 4-6. ✓
- Spec §9 owner actions → consolidated above. ✓
No spec section is unmapped. Bite-sized step detail + exact code produced per phase at execution time (multi-subsystem infra plan — see header).
