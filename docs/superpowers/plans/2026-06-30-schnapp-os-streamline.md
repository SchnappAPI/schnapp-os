# schnapp-os Streamline - Implementation Plan (phased)

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement each phase task-by-task. Steps use checkbox (`- [ ]`) syntax. **Phase 1 is detailed to task level; Phases 2–5 are task outlines - generate their step-level bite-sized detail (with exact code) at the start of that phase, when the code specifics are stable.**

**Goal:** Streamline schnapp-os per [the design spec](../specs/2026-06-30-schnapp-os-streamline-design.md) - one canonical source of truth, enforcement moved from shelf to gate, plugin flattened - without sacrificing capability.

**Architecture:** Two git repos split on the atomicity line: `schnapp-os` (system + system-state) and a new `schnapp-vault` (cross-surface knowledge, = the Obsidian vault). Enforcement funnels through surface-independent CI gates. Native `.claude/` discovery replaces the plugin.

**Tech Stack:** git + GitHub (private), bash hooks + GitHub Actions CI, Python (learning worker), 1Password `op` CLI, memory-mcp + obsidian-mcp (MCP servers), Obsidian.

## Global Constraints (verbatim, apply to every task)
- **Git = the one truth.** Nothing canonical lives outside git.
- **main-only, commit + push every change**; pull `--rebase --autostash` before push; never branch unless told; destructive ops need owner approval.
- **Secrets are `op://` references, never values.** New env vars → `.env.template` as `op://` URIs.
- **Instruction files** (`CLAUDE.md`, `agents.md`, rules) → the writing-style standard; everything else a deviation.
- **ISO 8601 dates** in filenames; spell names out; no force-push.
- **Keep-by-default**: change only with cause; this is not a rebuild.

## Phase sequencing (dependencies)
```
Phase 1 (vault) ──┬─> Phase 3 (gates)   [needs vault CI + flatten]
                  ├─> Phase 5 (Cowork)  [needs vault as shared store]
Phase 2 (flatten)─┘
Phase 4 (context discipline) - independent, run any time
```
Recommended order: **1 → (2 ∥ 4) → 3 → 5.** Each phase ends shippable.

---

## Phase 1 - Vault stand-up
**Deliverable:** `schnapp-vault` exists (private, local, = Obsidian vault), `memory/` migrated + schema-normalized, vault CI gate live (dead supersede-check FIXED), MCPs repointed.

**Owner-action gates in this phase (hard-to-reverse - confirm before running):**
- Create the GitHub repo (owner account).
- Move the Obsidian vault out of OneDrive (owner filesystem + OneDrive state).
- Repoint `memory-mcp` + `obsidian-mcp` (running services).

**Files:**
- Create: `~/code/schnapp-vault/{agents.md, index.md, README.md, .github/workflows/vault-freshness.yml, scripts/check-frontmatter.sh}`
- Move: `schnapp-os/memory/*` → `~/code/schnapp-vault/memory/`
- Modify: `schnapp-os` references to `memory/` (CLAUDE.md, README, session-hygiene, memory-mcp/obsidian-mcp config)

**Tasks:** (checkbox = live tracker; **Re-cut Fork A, 2026-07-01**: see note below)

> **Re-cut (Fork A, owner-approved 2026-07-01):** the vault already existed as `SchnappAPI/obsidian-vault` (2 clones). Task 1 became CONSOLIDATE-by-rename, not create-fresh. Also: gate 3 repoints a THIRD consumer the plan missed - the Obsidian **Brain Agent** (OneDrive-path-hardcoded, code lives in-vault at `.github/scripts/`) - and SPLITS (obsidian-mcp = local launchd; memory-mcp = Render config, owner-side). **Execution order:** 1 → 2 → 5 → 3+4 → 6 → 7 → 8 → 9 → 10 (checker before the data it verifies; memory stays in schnapp-os until task 8 repoints memory-mcp, then task 9 removes it - no empty-lane window, ACCURATE #1). Full rationale → ADR (task 10).

- [x] 1. **Consolidate the vault repo** *(Fork A)* - deleted empty `schnapp-vault`; renamed `obsidian-vault` → `schnapp-vault`; cloned to `~/code/schnapp-vault` (git-native, out of OneDrive). Verified: `rev-parse --show-toplevel` + non-cloud path. *(owner-confirmed)*
- [x] 2. **Author `agents.md` + `index.md`**: the narrow vault contract: the §3.5 flat schema (single definition site), supersede rule, capture-here, area rules, `/memory /areas /knowledge /reviews` layout. Verify: a human read + it names every schema field. *(done: vault `718f9be`; agents.md schema = exact §3.5, narrow, index+README reference-not-restate, no em dashes)*
- [x] 3. **Fold `memory/` into the vault**: copy each fact schnapp-os → vault `/memory` (do NOT remove from schnapp-os yet); scaffold `/areas/{work,personal,_adhoc}`, `/knowledge/{raw,raw/processed,wiki}`, `/reviews`. Verify: 12 facts present; MEMORY.md index regenerated. *(done: vault `167ecaa`; 12 facts copied, scaffold +.gitkeep, source untouched)*
- [x] 4. **Normalize every fact to the one schema**: un-nest `metadata:` → flat keys; drop `node_type`/`supersedes`-text; `scope`→`area`; add `description`/`type` where missing; `created:` = first git-commit date, `updated:` = last git-commit date; `superseded: false`. Verify: `check-frontmatter.sh` passes on all facts. *(done: `167ecaa`; check-frontmatter 12/12; kept 5 existing `type:` values; +link fix `f402248` for §10 cross-repo links)*
- [x] 5. **Write `check-frontmatter.sh`** (TDD) - fails on: nested `metadata:`, missing any required flat key, missing `updated:`, orphan `superseded: true` with no `[[successor]]`. FIXES the dead check (greps the flat top-level key, not an indented one). Test with fixtures (good + each bad case) before wiring. *(done: vault `6401757`; 9/9 fixtures assert the specific violation; +enum/date/name checks; fail-closes on quoted enum/date/name values)*
- [x] 6. **Wire `vault-freshness.yml`**: runs `check-frontmatter.sh` on push/PR; blocks on failure. Verify: a deliberately-bad fact fails CI; a good tree passes. *(done: vault `3137688`; real Actions run 28496925200 = success on good tree; bad-fact fail proven locally; process-inbox.yml untouched)*
- [x] 7. **Exit OneDrive**: make `~/code/schnapp-vault` the canonical Obsidian vault; retire the OneDrive + `~/code/obsidian-vault` copies from the write path; repoint the `~/Documents/Obsidian` symlink; open the folder in Obsidian. Verify: Obsidian reads it; `.git` NOT under any cloud-sync path. *(done 2026-07-01 per gate-2 spec: symlink → ~/code/schnapp-vault; both services healthy on new path; ZERO live OneDrive hardcodes; OneDrive + ~/code/obsidian-vault left as cold backups. Owner: open the vault in Obsidian to eyeball; symlink+.obsidian guarantee correct load.)*
- [x] 8. **Repoint consumers**: obsidian-mcp (local launchd, vault path) + Brain Agent (in-vault `.github/scripts` paths) + memory-mcp (Render `MEMORY_REPO`→schnapp-vault, token scope; owner-side). Verify: `memory_read`/`memory_list` return vault facts; `obsidian` tools read the same tree. *(LOCAL DONE in gate 2: obsidian-mcp `server.py:36` + Brain Agent scripts (dynamic `parents[2]`) + plist + CONNECTIONS.md repointed, services restarted + verified. gate-3 memory-mcp Render `MEMORY_REPO`→schnapp-vault + `SCHNAPP_OS_PAT` given vault R/W = DONE + VERIFIED 2026-07-01: memory_health repo=SchnappAPI/schnapp-vault authenticated, serving flat-schema facts.)*
- [x] 9. **Update schnapp-os references + remove `memory/`**: CLAUDE.md, README, `session-hygiene`, backup script stop pointing at `schnapp-os/memory/`; `git rm` the lane. Verify: freshness CI green; grep finds no live `schnapp-os/memory/` references. *(DONE 2026-07-01: relocated the SYSTEM PROCEDURES to `docs/memory-lane.md` (schema references vault `agents.md`, not restated); repointed hooks - `session-start-gate.sh` MEM→`~/code/schnapp-vault/memory` + satellite loop→vault, `capture-nudge.sh`/`session-end-backup.sh` refs, `backup-archive.sh` `OBSIDIAN_VAULT_DIR` default→vault; `autoMemoryDirectory`→`~/code/schnapp-vault/memory`; retargeted README/CLAUDE/session-hygiene/learn-route/grill-me/notes-lookup/memory-consolidation/memory-mcp README+tools.ts/credentials-map/surfaces/code-mac/templates + the 3 check-script comments; `git rm -r memory/`. Verified: gate runs clean (exit 0) scanning the vault's 14 facts, freshness CI green, secret scan 0 BLOCK, grep clean of LIVE refs. USER-scope `~/.claude/settings.json` `autoMemoryDirectory` = owner per-machine edit, outside repo.)*
- [x] 10. **Write ADR**: two-repo split + git=one-truth + vault-out-of-OneDrive + Fork-A consolidation. Flip PLAN/PROGRESS. Commit + push both repos. *(done: [decisions/0023](../../../decisions/0023-two-repo-vault-split-flat-memory-schema.md); user-scope `autoMemoryDirectory` set on this machine; logged the memory-mcp/Obsidian vault auto-commit follow-up.)*

**Done when:** vault CI green, all facts one-schema, MCPs serve the vault, schnapp-os no longer owns `memory/`. ✅ **ALL MET 2026-07-01 - PHASE 1 COMPLETE.**

**Follow-ups (not Phase-1-blocking, tracked for later):**
- Vault auto-commit/push: obsidian-mcp + Obsidian write the vault working tree but do not git-commit, so git truth lags Obsidian edits (gate-2 spec design note). The vault needs an auto-commit mechanism as memory-mcp has.
- USER-scope `~/.claude/settings.json` `autoMemoryDirectory` → `~/code/schnapp-vault/memory` on EVERY OTHER machine (done on this Mac).
- `~/code/obsidian-vault` stale clone: left in place (2 uncommitted Inbox deletions blocked the spec's clean-only auto-remove); prune manually when convenient.

---

## Phase 2 - Flatten the plugin
**Deliverable:** native `.claude/` layout; marketplace + plugin.json gone; all references retargeted; hooks still fire.

**Target layout:** `plugins/core/{skills,commands,agents}` → `.claude/{skills,commands,agents}` (native discovery); `plugins/core/{rules,scripts,hooks}` → top-level `rules/ scripts/ hooks/`; `plugins/core/CATALOG.md` → root `CATALOG.md`. Delete `.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`.

**Execution constraint (why the grouping below):** gen-catalog + `freshness.yml` + `ci-lint.yml` + all 6 hooks reference `plugins/core/` paths, and every pushed commit must keep CI green and hooks firing. So a move is atomic with the executable references that point at it; pure-doc references sweep after. **PLAN.md is left untouched**: already stale post-Phase-1 (`claude-kit/`/`memory/`/`presets/`); Phase 4 reconciles it wholesale, a partial retarget here would be incoherent half-work.

**Owner-action gate (hard-to-reverse - PAUSE for explicit owner confirmation before running):**
1. `~/.claude/CLAUDE.md` PER MACHINE: the 7 `@~/code/schnapp-os/plugins/core/rules/global/*.md` lines + the prose path → `rules/global/`.
2. `claude plugin uninstall schnapp-os-core@schnapp-os` (matches by NAME - confirm target; [[plugin-registry-snapshot-gotchas]]).
3. `~/.claude/settings.json` (user scope): remove `"schnapp-os-core@schnapp-os": true` from `enabledPlugins` and the `extraKnownMarketplaces.schnapp-os` block.
4. Re-render + reload the 2 launchd plists (`__REPO__/plugins/core/scripts/` bakes into the installed copy) per `scheduled-tasks/README.md`.

**Tasks (checkbox = live tracker; step-level detail generated at execution, 2026-07-01):**

- [x] **T1. Atomic flatten + rewire executables** *(covers outline 1, 2, and the executable half of 4)*. `git mv` the 6 dirs + `plugins/core/CATALOG.md`→`CATALOG.md`. Rewrite `scripts/gen-catalog.sh` (REPO depth `../../..`→`..`; drop `CORE`; scan `$REPO/rules`, `$REPO/.claude/{skills,commands,agents}`, `$REPO/hooks`; `OUT=$REPO/CATALOG.md`; header text + `freshness.yml` link). Repoint every executable/config ref off `plugins/core/`: `.claude/settings.json` (6 hook paths + `$comment`), `scripts/check-freshness.sh`, `.github/workflows/{freshness,ci-lint}.yml`, `scripts/{learning-worker,learning-gate,scan-secrets,backup-archive,learning_distill.py}`, `hooks/{session-start-gate,shellcheck-on-write}.sh` + `hooks/hooks.json`, `scripts/tests/{test-learning-gate,test-learning-worker}.sh` + `secret-fixtures.txt`, both `scheduled-tasks/*.plist` (`__REPO__/plugins/core/scripts/`→`__REPO__/scripts/`), `scheduled-tasks/run-ci-routines.sh`. Regenerate `CATALOG.md`. **Verify:** `git grep -n plugins/core -- scripts hooks .github/workflows .claude/settings.json 'scheduled-tasks/*.plist' scheduled-tasks/run-ci-routines.sh` = 0; `bash scripts/check-freshness.sh` = ok; `bash -n` all `hooks/*.sh scripts/*.sh`; each `.claude/settings.json` hook path resolves; plists load (`plistlib`). Commit + push; CI green.
- [x] **T2. Delete plugin manifests** *(outline 3, repo half)*. `git rm .claude-plugin/marketplace.json plugins/core/.claude-plugin/plugin.json`; drop now-empty `plugins/`, `.claude-plugin/`. **Verify:** no `marketplace.json`/`plugin.json`; `plugins/` gone; CI green. Commit + push.
- [x] **T3. Retarget live docs** *(outline 4, doc half)*. Sweep `plugins/core/`→new paths in LIVE files only: `CLAUDE.md`, `README.md`, `docs/{framework,memory-lane,headless-claude-auth}.md`, `surfaces/*.md`, `templates/{project-CLAUDE,user-global-CLAUDE}.md`, `scheduled-tasks/{README,doc-freshness-sweep,infra-health}.md`, `credentials-map.md`, `.gitignore` (comment), moved `.claude/skills/*/SKILL.md` (cleanse-secrets, learn-route, rules-distill, session-hygiene, status) + `.claude/agents/secrets-leak-reviewer.md` + `rules/modules/lang/git.md`; `plugins/core/CATALOG.md`→`CATALOG.md`. **Leave untouched:** `handoffs/*`, `decisions/*`, `docs/archive/*`, `docs/repo-review-*`, `docs/intent-capture-*`, `docs/superpowers/plans/2026-06-27-*`, `docs/superpowers/specs/2026-06-17-*`, `PROGRESS.md` past lines, `PLAN.md`, `AUDIT.md`. **Verify:** `git grep -l plugins/core` returns only the leave-list. Commit + push.
- [x] **T3b. Repair move-broken relative links** *(T1 fallout, surfaced during T3 review)*. The T1 `git mv` shifted directory depth, silently breaking `../`-relative markdown links inside the moved `.claude/` files (they carry no `plugins/core` text, so T3's residual gate could not see them): links to now-root targets (`rules/`, `CATALOG.md`) needed **+1** `../`; links to unmoved root targets (`decisions/`, `credentials-map.md`, `surfaces/`, `scheduled-tasks/`) needed **−1**. Repaired all 50 links across 20 `.claude/` files (strip leading `../`, recompute relpath to the real target). **Verify:** broken-link re-scan over `.claude/`+`rules/` = 0; freshness OK. Commit + push.
- [x] **T4. ADR + trackers** *(outline 5, repo half)*. Write `decisions/0024-flatten-plugin-native-claude.md` (executes 0011 #2; native discovery replaces the plugin; moots stale-plugin-pin + the double-load). Flip these boxes; close the `PROGRESS.md` open item `#2 repo-flattening`; append the Phase-2 bullet. Commit + push.
- [x] **OWNER GATE - DONE on this Mac 2026-07-01.** Owner ran all 5 steps (pull, `~/.claude/CLAUDE.md` @import → `rules/global/`, `claude plugin uninstall schnapp-os-core@schnapp-os`, drop user-scope `enabledPlugins`+`extraKnownMarketplaces.schnapp-os`, re-render+reload the 2 plists). Verified: plugin gone, 0 `plugins/core` in CLAUDE.md, settings entries removed, main checkout at `main` with `rules/global/` present + `plugins/core` gone. OTHER machines owe the same one-time steps (handoff 045).
- [x] **T5. Verify double-load gone + final review + handoff** *(outline 5, verify half)*. Double-load GONE (plugin uninstalled + this session's skill registry shows native, un-namespaced names; 23 native skills). Hooks live-fire clean from the flattened layout (all 6, incl. session-start-gate's retargeted `scripts/` deps). Final whole-branch review (Opus) done → fixed 2 more depth-class escapees + a stray pyc (`83bc3f5`). Handoff [045](../../../handoffs/045-phase-2-flatten-complete.md) written.

**Done when:** no plugin/marketplace remains, native discovery + hooks verified, freshness CI green, double-load resolved. ✅ **ALL MET 2026-07-01 - PHASE 2 COMPLETE.**

---

## Phase 3 - Enforcement gates
**Deliverable:** the recurring deterministic classes are gated; the learning loop emits gates.

**Tasks (checkbox = live tracker; step-level detail generated at execution, 2026-07-01):**

- [x] **T1. Malformed-secret byte-check gate (TDD, security).** Build `scripts/check-secret-bytes.sh`: validate a secret value's RAW BYTES without EVER printing the value. Input via `--ref op://...` (live: it `op read`s) OR on stdin (tests). Fail (exit 1) on: empty; leading/trailing whitespace, newline, or CR; wrapping single/double quotes; length below `--min-len N` (truncation); `--expect-prefix S` mismatch. Report only the DEFECT CATEGORY, never any bytes of the value. TDD first: `scripts/tests/test-check-secret-bytes.sh` with stdin fixtures (clean passes; leading-space / wrapped-quotes / trailing-newline / too-short / prefix-mismatch each fail with the right category; a fixture asserts the value is NEVER echoed). Gate the test in `freshness.yml`. Grow `rotate-secret` SKILL step 6 (Verify) with a byte-check line invoking the gate on the new ref ([[malformed-stored-secret-401]]). Regenerate CATALOG. **Verify:** test pass=N/0; output never contains the fixture value; `bash -n` + shellcheck clean; freshness OK; rotate-secret cites the gate.
- [x] **T2. Loop rewire: recurrence drafts a gate, not prose.** The nightly `learning-worker` counts error-class frequency over the capture archive; when a class recurs (>= 2), it drafts a GATE proposal (a check, as a GitHub issue for owner approval) instead of another prose fact, and NEVER auto-lands the gate. Design the class signature (deterministic), the archive count, and the drafted-issue body. TDD with a seeded repeat class in dry-run (no real gh/network): >= 2 same-class captures produce a drafted-gate issue body; a single occurrence does not. **Verify:** seeded repeat-class fixture yields a drafted-gate proposal (not a rule/fact edit); single-occurrence does not; test green; nothing autonomous lands a gate on main. *(design-heavy: touches the autonomous self-editing loop.)* *(done 2026-07-01: `scripts/learning-recurrence.sh` + worker rewire; recurrence >=2 drafts a GitHub-issue gate, marked drafted only when the issue actually files (gh-fail -> prose fallback + retry, no orphaning); never auto-lands (`learning-gate.sh` byte-unchanged, auto-land scope stays `.md` under rules/memory). TDD 28+14 + a live-path gh-shim harness 16; spec review Approved, adversarial review HOLD -> fixed (A1 orphaning + Minors). Commits a9acefc + e419fbc.)*
- [x] **T3. Extend `last-verified` coverage.** The mechanism already exists in `check-freshness.sh` (a doc opts in with `last-verified: DATE` + a source list; CI fails if a source changed after the date). Add `last-verified` frontmatter to deterministic docs whose accuracy tracks a specific checkable source (candidates: `credentials-map.md`, `connectors/*/README.md`, surface profiles). Pick only docs with a clear source. **Verify:** each added doc names a real source; `check-freshness.sh` passes today; a deliberately-stale fixture (source newer than the date) FAILS. *(done 2026-07-01: added last-verified frontmatter to `credentials-map.md` (source `.env.template`) + `connectors/{github-mcp,mac-mcp,obsidian-mcp}/README.md` (source that dir's `server.py`); each source verified present + not newer than the date; check-freshness passes today; a deliberately-stale fixture proven to FAIL (exit 1, STALE named the doc) then removed.)*
- [x] **T4. ADR + trackers + close.** ADR `decisions/0026` (enforcement ladder advisory -> memory -> Code hook -> CI gate; recurrence >= 2 escalates; deterministic -> gate, judgment -> stay advisory; do not gate the un-recurred). Flip boxes; PROGRESS; push. Final whole-branch review + handoff. *(done 2026-07-01: [decisions/0026](../../../decisions/0026-enforcement-ladder-recurrence-escalation.md); Phase-3 final whole-branch review (opus) = READY-TO-CLOSE, cardinal no-auto-land invariant proven end-to-end + ADR accurate + trackers consistent; em dashes stripped from 0026 per writing-style; handoff 048.)*

**Done when:** malformed-secret is gated + TDD-tested + wired into `rotate-secret`; a seeded repeat class produces a drafted-gate issue (not a prose fact); `last-verified` covers more deterministic docs with a proven stale-fail; ADR 0026 records the ladder. ✅ **ALL MET 2026-07-01: PHASE 3 COMPLETE.**

---

## Phase 4 - Context / reference discipline
**Deliverable:** anti-bloat writing-style rule in force globally; `PLAN.md` reconciled to a thin pointer + archive; soft length-advisory live; handoffs navigable via a thin index.

**Owner-action (additive, low-risk - NO hard pause):** one `@import` line added to each machine's `~/.claude/CLAUDE.md` (writing-style.md). Done on this Mac + the canonical template; other machines owe the one-liner (handoff).

**Tasks (checkbox = live tracker; step-level detail generated at execution, 2026-07-01):**

- [x] **T1. Author + wire the writing-style rule.** Create `rules/global/writing-style.md` codifying the instruction-file writing standard (terse imperative, lead with the point, no em dashes, no preamble/fluff/hedging, reference-don't-restate, one-screen-where-possible) - it is referenced across the plan/spec today but never defined. De-dup (anti-stale): it OWNS file-writing mechanics and REFERENCES `naming-discipline.md` (names) + `anti-stale.md` (one-home) instead of restating; note it governs durable FILES while `working-style.md` governs owner-facing replies. Wire global: add `@~/code/schnapp-os/rules/global/writing-style.md` to `templates/user-global-CLAUDE.md` (bump the "7 files" prose → 8) + this Mac's `~/.claude/CLAUDE.md`. Regenerate `CATALOG.md`. **Verify:** rule exists, terse, zero em dashes; CATALOG lists it; @import present; freshness OK.
- [x] **T2. Reconcile PLAN.md (mirror ADR-0022).** Grep PLAN.md for open/pending/deferred/left/TODO (8 hits); verify each is tracked elsewhere (streamline plan / `decisions/` / PROGRESS open-items) or carry it forward explicitly - no active work lost. Snapshot full PLAN.md verbatim → `docs/archive/PLAN-archive-2026-07-01.md` (append-only history, never edited after). Replace PLAN.md with a thin live pointer (<~150 lines): what it was (original 11-Part build, all Parts closed), where live planning is now (`docs/superpowers/plans/`, per-initiative), decisions → `decisions/`, status → `PROGRESS.md`, plus any carried-forward open items. Retarget docs citing PLAN.md AS the status source (`CLAUDE.md`, `README.md`) → `PROGRESS.md` + the plan docs. ADR `decisions/0025` (PLAN.md retired to a pointer; executes 0011's backlog-reframing, mirrors 0022). **Verify:** PLAN.md <~150 lines; archive exists; open-item grep clean or carried; PLAN.md links in live docs still resolve; freshness OK.
- [x] **T3. Soft length-advisory (TDD, WARN / exit 0).** `hooks/length-advisory.sh` - on Write|Edit of an always-load or `rules/` file, WARN (never block; always exit 0) when the file exceeds a heuristic line threshold. Write fixtures first (over-long → WARN; normal → silent), then wire PostToolUse in `.claude/settings.json` (Code-time point-of-action nudge). **Verify:** over-long fixture WARNs at exit 0; normal file silent; `bash -n` clean; the settings.json path resolves.
- [x] **T4. Thin handoff index (index-in-place, NO physical move).** Add `handoffs/README.md`: a thin index (number → one-line title, newest-first; mark the newest as the resume point) over all 46 handoffs. Do NOT move any handoff file - 30 cross-references point at `handoffs/NNN…md` by path; moving re-breaks the Phase-2 link class for zero navigability the index does not already give. **Verify:** index lists all 46; newest flagged; every `handoffs/NNN` path still resolves (0 broken); freshness OK.

**Done when:** writing-style rule loads globally + is in CATALOG; PLAN.md < ~150 lines with pointer + archive + ADR 0025, no active work lost; length-advisory WARNs on an over-long fixture at exit 0; handoffs have a thin index with 0 broken links. ✅ **ALL MET 2026-07-01 - PHASE 4 COMPLETE** (handoff 046; Opus whole-branch review + stale-reference-class fix `9ceb382`).

---

## Phase 5 - Cowork two-way handoff
**Deliverable:** Code ↔ Cowork hand off through the shared git repos.

**Owner-action legs (run in Cowork - cannot run from Code; exact runbook: [handoff 049](../../../handoffs/049-phase-5-cowork-packet-repo-side.md)):** the T1 verify, the T3 probe, and the Cowork + return halves of the T4 round-trip.

**Tasks (checkbox = live tracker; step-level detail generated at execution, 2026-07-01):**

- [x] **T1. Connector vault access** *(outline 1)*. No grant to add: the connector's github leg (github-mcp) authenticates with `GITHUB_PAT`, all-repos ([credentials-map](../../../credentials-map.md)), so `SchnappAPI/schnapp-vault` is already in scope. Remaining = the VERIFY: a Cowork session reads a vault fact + writes one through the connector, scripted as [surfaces/cowork.md](../../../surfaces/cowork.md) enablement 3 + handoff 049 Cowork leg. *(repo-side done 2026-07-01: probe scripted, PAT scope confirmed; VERIFIED 2026-07-01 from Cowork: read vault MEMORY.md + wrote `memory/cowork-vault-write-verified.md` via github-mcp, flat 8-key schema, vault CI green; handoff 050)*
- [x] **T2. Handoff-packet convention, folded into `session-hygiene`** *(outline 2)*. Canonical home: [docs/memory-lane.md](../../../docs/memory-lane.md) "Handoff packet" (write-on-stop = the end-of-session write: working-memory facts + newest handoff + indexes, BOTH repos pushed; read-on-start = the freshness gate). `session-hygiene` carries the hookless transport (connector read-modify-write file commits, byte-exact `handoffs/README.md` emulation with CI verifying equivalence next push); `surfaces/cowork.md` de-staled (dead plugin-install path dropped per decisions/0024) + points at the packet. **Verify:** freshness + ci-lint + writing-style gates green; the packet defined in exactly one home, referenced elsewhere. *(done 2026-07-01)*
- [x] **T3. (optional, owner probe) memory-mcp from Cowork** *(outline 3)*. Probe scripted (cowork.md enablement 4 + handoff 049 Cowork leg): `memory_health`/`memory_list` in a Cowork session; healthy = schema-validated `memory_*` writes become the memory-leg front-line per the [decisions/0027](../../../decisions/0027-cowork-handoff-packet-over-git.md) upgrade path. *(probed 2026-07-01 from Cowork: memory_health authenticated, repo=SchnappAPI/schnapp-vault, branch=main; memory_list serves 14 flat-schema facts; memory_* writes = the memory-leg front line per 0027; handoff 050)*
- [x] **T4. Round-trip + ADR + trackers** *(outline 4)*. ADR [decisions/0027](../../../decisions/0027-cowork-handoff-packet-over-git.md) (packet over git; connector transport; generated-index emulation; memory-mcp as upgrade). Trackers flipped + pushed. Round-trip = Code (this session wrote packet 049) → Cowork (resume from 049, work, write packet 050) → Code (verify nothing lost, close). *(repo-side + the Code leg done 2026-07-01; Cowork leg done 2026-07-01, packet 050 written; return Code leg VERIFIED 2026-07-01: handoff 050 + index line landed byte-identical to `gen-handoff-index.sh`, freshness + writing-style gates green, vault fact + MEMORY.md line landed with vault CI green, PROGRESS line + T1/T3 flips present - nothing lost; handoff 051)*

**Done when:** a Code→Cowork→Code round-trip preserves state end-to-end. ✅ **MET 2026-07-01 - PHASE 5 COMPLETE; STREAMLINE PLAN CLOSED** (return leg verified nothing lost; handoff 051).

---

## Owner action items (consolidated)
1. **Phase 1:** confirm repo creation, OneDrive exit, MCP repoint.
2. **Phase 2:** per-machine `~/.claude/CLAUDE.md` `@import` edit; uninstall cached plugin.
3. **Phase 5:** ✅ done 2026-07-01 - connector vault-access verified, memory-mcp probed, round-trip closed (handoffs 049/050/051).
4. **Anytime:** prune the dead `brain-capture` claude.ai connector.

## Self-review - spec coverage
- Spec §3 (source of truth) → Phase 1. ✓
- Spec §4 (enforcement) → Phase 3 + Phase 1 CI. ✓
- Spec §5 (context discipline) → Phase 4. ✓
- Spec §6 (capability/flatten) → Phase 2. ✓
- Spec §7 (Cowork) → Phase 5. ✓
- Spec §3.5 schema / dead-check fix → Phase 1 tasks 4-6. ✓
- Spec §9 owner actions → consolidated above. ✓
No spec section is unmapped. Bite-sized step detail + exact code produced per phase at execution time (multi-subsystem infra plan - see header).
