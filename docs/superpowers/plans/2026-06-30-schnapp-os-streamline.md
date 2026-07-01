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

**Tasks:** (checkbox = live tracker; **Re-cut Fork A, 2026-07-01** — see note below)

> **Re-cut (Fork A, owner-approved 2026-07-01):** the vault already existed as `SchnappAPI/obsidian-vault` (2 clones). Task 1 became CONSOLIDATE-by-rename, not create-fresh. Also: gate 3 repoints a THIRD consumer the plan missed — the Obsidian **Brain Agent** (OneDrive-path-hardcoded, code lives in-vault at `.github/scripts/`) — and SPLITS (obsidian-mcp = local launchd; memory-mcp = Render config, owner-side). **Execution order:** 1 → 2 → 5 → 3+4 → 6 → 7 → 8 → 9 → 10 (checker before the data it verifies; memory stays in schnapp-os until task 8 repoints memory-mcp, then task 9 removes it — no empty-lane window, ACCURATE #1). Full rationale → ADR (task 10).

- [x] 1. **Consolidate the vault repo** *(Fork A)* — deleted empty `schnapp-vault`; renamed `obsidian-vault` → `schnapp-vault`; cloned to `~/code/schnapp-vault` (git-native, out of OneDrive). Verified: `rev-parse --show-toplevel` + non-cloud path. *(owner-confirmed)*
- [x] 2. **Author `agents.md` + `index.md`** — the narrow vault contract: the §3.5 flat schema (single definition site), supersede rule, capture-here, area rules, `/memory /areas /knowledge /reviews` layout. Verify: a human read + it names every schema field. *(done: vault `718f9be`; agents.md schema = exact §3.5, narrow, index+README reference-not-restate, no em dashes)*
- [x] 3. **Fold `memory/` into the vault** — copy each fact schnapp-os → vault `/memory` (do NOT remove from schnapp-os yet); scaffold `/areas/{work,personal,_adhoc}`, `/knowledge/{raw,raw/processed,wiki}`, `/reviews`. Verify: 12 facts present; MEMORY.md index regenerated. *(done: vault `167ecaa`; 12 facts copied, scaffold +.gitkeep, source untouched)*
- [x] 4. **Normalize every fact to the one schema** — un-nest `metadata:` → flat keys; drop `node_type`/`supersedes`-text; `scope`→`area`; add `description`/`type` where missing; `created:` = first git-commit date, `updated:` = last git-commit date; `superseded: false`. Verify: `check-frontmatter.sh` passes on all facts. *(done: `167ecaa`; check-frontmatter 12/12; kept 5 existing `type:` values; +link fix `f402248` for §10 cross-repo links)*
- [x] 5. **Write `check-frontmatter.sh`** (TDD) — fails on: nested `metadata:`, missing any required flat key, missing `updated:`, orphan `superseded: true` with no `[[successor]]`. FIXES the dead check (greps the flat top-level key, not an indented one). Test with fixtures (good + each bad case) before wiring. *(done: vault `6401757`; 9/9 fixtures assert the specific violation; +enum/date/name checks; fail-closes on quoted enum/date/name values)*
- [x] 6. **Wire `vault-freshness.yml`** — runs `check-frontmatter.sh` on push/PR; blocks on failure. Verify: a deliberately-bad fact fails CI; a good tree passes. *(done: vault `3137688`; real Actions run 28496925200 = success on good tree; bad-fact fail proven locally; process-inbox.yml untouched)*
- [x] 7. **Exit OneDrive** — make `~/code/schnapp-vault` the canonical Obsidian vault; retire the OneDrive + `~/code/obsidian-vault` copies from the write path; repoint the `~/Documents/Obsidian` symlink; open the folder in Obsidian. Verify: Obsidian reads it; `.git` NOT under any cloud-sync path. *(done 2026-07-01 per gate-2 spec: symlink → ~/code/schnapp-vault; both services healthy on new path; ZERO live OneDrive hardcodes; OneDrive + ~/code/obsidian-vault left as cold backups. Owner: open the vault in Obsidian to eyeball; symlink+.obsidian guarantee correct load.)*
- [x] 8. **Repoint consumers** — obsidian-mcp (local launchd, vault path) + Brain Agent (in-vault `.github/scripts` paths) + memory-mcp (Render `MEMORY_REPO`→schnapp-vault, token scope; owner-side). Verify: `memory_read`/`memory_list` return vault facts; `obsidian` tools read the same tree. *(LOCAL DONE in gate 2: obsidian-mcp `server.py:36` + Brain Agent scripts (dynamic `parents[2]`) + plist + CONNECTIONS.md repointed, services restarted + verified. gate-3 memory-mcp Render `MEMORY_REPO`→schnapp-vault + `SCHNAPP_OS_PAT` given vault R/W = DONE + VERIFIED 2026-07-01: memory_health repo=SchnappAPI/schnapp-vault authenticated, serving flat-schema facts.)*
- [x] 9. **Update schnapp-os references + remove `memory/`** — CLAUDE.md, README, `session-hygiene`, backup script stop pointing at `schnapp-os/memory/`; `git rm` the lane. Verify: freshness CI green; grep finds no live `schnapp-os/memory/` references. *(DONE 2026-07-01: relocated the SYSTEM PROCEDURES to `docs/memory-lane.md` (schema references vault `agents.md`, not restated); repointed hooks — `session-start-gate.sh` MEM→`~/code/schnapp-vault/memory` + satellite loop→vault, `capture-nudge.sh`/`session-end-backup.sh` refs, `backup-archive.sh` `OBSIDIAN_VAULT_DIR` default→vault; `autoMemoryDirectory`→`~/code/schnapp-vault/memory`; retargeted README/CLAUDE/session-hygiene/learn-route/grill-me/notes-lookup/memory-consolidation/memory-mcp README+tools.ts/credentials-map/surfaces/code-mac/templates + the 3 check-script comments; `git rm -r memory/`. Verified: gate runs clean (exit 0) scanning the vault's 14 facts, freshness CI green, secret scan 0 BLOCK, grep clean of LIVE refs. USER-scope `~/.claude/settings.json` `autoMemoryDirectory` = owner per-machine edit, outside repo.)*
- [x] 10. **Write ADR** — two-repo split + git=one-truth + vault-out-of-OneDrive + Fork-A consolidation. Flip PLAN/PROGRESS. Commit + push both repos. *(done: [decisions/0023](../../../decisions/0023-two-repo-vault-split-flat-memory-schema.md); user-scope `autoMemoryDirectory` set on this machine; logged the memory-mcp/Obsidian vault auto-commit follow-up.)*

**Done when:** vault CI green, all facts one-schema, MCPs serve the vault, schnapp-os no longer owns `memory/`. ✅ **ALL MET 2026-07-01 — PHASE 1 COMPLETE.**

**Follow-ups (not Phase-1-blocking, tracked for later):**
- Vault auto-commit/push: obsidian-mcp + Obsidian write the vault working tree but do not git-commit, so git truth lags Obsidian edits (gate-2 spec design note). The vault needs an auto-commit mechanism as memory-mcp has.
- USER-scope `~/.claude/settings.json` `autoMemoryDirectory` → `~/code/schnapp-vault/memory` on EVERY OTHER machine (done on this Mac).
- `~/code/obsidian-vault` stale clone: left in place (2 uncommitted Inbox deletions blocked the spec's clean-only auto-remove); prune manually when convenient.

---

## Phase 2 — Flatten the plugin
**Deliverable:** native `.claude/` layout; marketplace + plugin.json gone; all references retargeted; hooks still fire.

**Target layout:** `plugins/core/{skills,commands,agents}` → `.claude/{skills,commands,agents}` (native discovery); `plugins/core/{rules,scripts,hooks}` → top-level `rules/ scripts/ hooks/`; `plugins/core/CATALOG.md` → root `CATALOG.md`. Delete `.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`.

**Execution constraint (why the grouping below):** gen-catalog + `freshness.yml` + `ci-lint.yml` + all 6 hooks reference `plugins/core/` paths, and every pushed commit must keep CI green and hooks firing. So a move is atomic with the executable references that point at it; pure-doc references sweep after. **PLAN.md is left untouched** — already stale post-Phase-1 (`claude-kit/`/`memory/`/`presets/`); Phase 4 reconciles it wholesale, a partial retarget here would be incoherent half-work.

**Owner-action gate (hard-to-reverse — PAUSE for explicit owner confirmation before running):**
1. `~/.claude/CLAUDE.md` PER MACHINE: the 7 `@~/code/schnapp-os/plugins/core/rules/global/*.md` lines + the prose path → `rules/global/`.
2. `claude plugin uninstall schnapp-os-core@schnapp-os` (matches by NAME — confirm target; [[plugin-registry-snapshot-gotchas]]).
3. `~/.claude/settings.json` (user scope): remove `"schnapp-os-core@schnapp-os": true` from `enabledPlugins` and the `extraKnownMarketplaces.schnapp-os` block.
4. Re-render + reload the 2 launchd plists (`__REPO__/plugins/core/scripts/` bakes into the installed copy) per `scheduled-tasks/README.md`.

**Tasks (checkbox = live tracker; step-level detail generated at execution, 2026-07-01):**

- [x] **T1. Atomic flatten + rewire executables** *(covers outline 1, 2, and the executable half of 4)*. `git mv` the 6 dirs + `plugins/core/CATALOG.md`→`CATALOG.md`. Rewrite `scripts/gen-catalog.sh` (REPO depth `../../..`→`..`; drop `CORE`; scan `$REPO/rules`, `$REPO/.claude/{skills,commands,agents}`, `$REPO/hooks`; `OUT=$REPO/CATALOG.md`; header text + `freshness.yml` link). Repoint every executable/config ref off `plugins/core/`: `.claude/settings.json` (6 hook paths + `$comment`), `scripts/check-freshness.sh`, `.github/workflows/{freshness,ci-lint}.yml`, `scripts/{learning-worker,learning-gate,scan-secrets,backup-archive,learning_distill.py}`, `hooks/{session-start-gate,shellcheck-on-write}.sh` + `hooks/hooks.json`, `scripts/tests/{test-learning-gate,test-learning-worker}.sh` + `secret-fixtures.txt`, both `scheduled-tasks/*.plist` (`__REPO__/plugins/core/scripts/`→`__REPO__/scripts/`), `scheduled-tasks/run-ci-routines.sh`. Regenerate `CATALOG.md`. **Verify:** `git grep -n plugins/core -- scripts hooks .github/workflows .claude/settings.json 'scheduled-tasks/*.plist' scheduled-tasks/run-ci-routines.sh` = 0; `bash scripts/check-freshness.sh` = ok; `bash -n` all `hooks/*.sh scripts/*.sh`; each `.claude/settings.json` hook path resolves; plists load (`plistlib`). Commit + push; CI green.
- [x] **T2. Delete plugin manifests** *(outline 3, repo half)*. `git rm .claude-plugin/marketplace.json plugins/core/.claude-plugin/plugin.json`; drop now-empty `plugins/`, `.claude-plugin/`. **Verify:** no `marketplace.json`/`plugin.json`; `plugins/` gone; CI green. Commit + push.
- [x] **T3. Retarget live docs** *(outline 4, doc half)*. Sweep `plugins/core/`→new paths in LIVE files only: `CLAUDE.md`, `README.md`, `docs/{framework,memory-lane,headless-claude-auth}.md`, `surfaces/*.md`, `templates/{project-CLAUDE,user-global-CLAUDE}.md`, `scheduled-tasks/{README,doc-freshness-sweep,infra-health}.md`, `credentials-map.md`, `.gitignore` (comment), moved `.claude/skills/*/SKILL.md` (cleanse-secrets, learn-route, rules-distill, session-hygiene, status) + `.claude/agents/secrets-leak-reviewer.md` + `rules/modules/lang/git.md`; `plugins/core/CATALOG.md`→`CATALOG.md`. **Leave untouched:** `handoffs/*`, `decisions/*`, `docs/archive/*`, `docs/repo-review-*`, `docs/intent-capture-*`, `docs/superpowers/plans/2026-06-27-*`, `docs/superpowers/specs/2026-06-17-*`, `PROGRESS.md` past lines, `PLAN.md`, `AUDIT.md`. **Verify:** `git grep -l plugins/core` returns only the leave-list. Commit + push.
- [x] **T3b. Repair move-broken relative links** *(T1 fallout, surfaced during T3 review)*. The T1 `git mv` shifted directory depth, silently breaking `../`-relative markdown links inside the moved `.claude/` files (they carry no `plugins/core` text, so T3's residual gate could not see them): links to now-root targets (`rules/`, `CATALOG.md`) needed **+1** `../`; links to unmoved root targets (`decisions/`, `credentials-map.md`, `surfaces/`, `scheduled-tasks/`) needed **−1**. Repaired all 50 links across 20 `.claude/` files (strip leading `../`, recompute relpath to the real target). **Verify:** broken-link re-scan over `.claude/`+`rules/` = 0; freshness OK. Commit + push.
- [x] **T4. ADR + trackers** *(outline 5, repo half)*. Write `decisions/0024-flatten-plugin-native-claude.md` (executes 0011 #2; native discovery replaces the plugin; moots stale-plugin-pin + the double-load). Flip these boxes; close the `PROGRESS.md` open item `#2 repo-flattening`; append the Phase-2 bullet. Commit + push.
- [ ] **OWNER GATE — PAUSE.** Present the 4 exact commands above; owner confirms/runs (per machine).
- [ ] **T5. Verify double-load gone + final review + handoff** *(outline 5, verify half)*. After the owner uninstall: a fresh in-repo session lists each skill/command/agent ONCE (native, un-namespaced) — no `schnapp-os-core:*`. Live-fire hooks (`claude -p --include-hook-events "exit"`). Final whole-branch review. Write handoff 045.

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
