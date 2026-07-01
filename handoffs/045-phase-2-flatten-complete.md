# Handoff 045 — Phase 2 (flatten plugin → native `.claude/`) COMPLETE; resume = Phase 3, 4, or 5

**Date:** 2026-07-01. **Surface:** Claude Code on the Mac, Opus 4.8, subagent-driven.
**Status:** schnapp-os streamline **Phase 2 DONE + verified end-to-end** (repo work + owner gate on
this Mac). This handoff carries the NEW current-state map (verify against it, do not reconstruct).

## What Phase 2 delivered (all on `main`, CI green on every commit)
- **Native `.claude/` layout.** `plugins/core/{skills,commands,agents}` → `.claude/{skills,commands,agents}`;
  `{rules,scripts,hooks}` → top-level; `CATALOG.md` → repo root. (T1 `c96783b`)
- **Plugin + marketplace deleted.** `.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`
  gone; the `plugins/` tree is removed. (T2 `3e1c446`)
- **All references retargeted.** Every executable/config ref (`.claude/settings.json` hooks,
  `gen-catalog`, `freshness.yml`+`ci-lint.yml`, learning-loop scripts, hooks, tests, both launchd
  plists, `run-ci-routines`) in T1; ~24 LIVE docs (CLAUDE/README/templates/surfaces/scheduled-tasks/
  docs + moved SKILL/agent/rule internal refs) in T3 (`7f300bc`). **`PLAN.md` deliberately left** for
  Phase 4's wholesale reconcile (already stale post-Phase-1: `claude-kit/`, `memory/`, `presets/`).
- **Move fallout repaired.** T1's `git mv` shifted directory depth → (a) 50 broken `../`-relative
  markdown links across 20 `.claude/` files, fixed in T3b (`5f29a72`); (b) 3 location-derived-root
  escapees of the "loses 2 path levels" class — `learning_distill.py` (caught in T1 review),
  `learning-eval.sh` + `test-supersede-orphans.sh` (caught in the final whole-branch review,
  `83bc3f5`). Class now exhaustively swept.
- **Double-load resolved.** Owner uninstalled `schnapp-os-core@schnapp-os`; global rules now `@import`
  from `~/code/schnapp-os/rules/global/`. Skills load native (un-namespaced), each exactly once.
- ADR: [decisions/0024](../decisions/0024-flatten-plugin-native-claude.md).

## Current-state map (VERIFIED 2026-07-01 on THIS Mac — verify, don't reconstruct)
- **Layout:** native `.claude/{skills (23), commands (3), agents (3)}` + top-level `rules/ scripts/ hooks/`
  + root `CATALOG.md`. NO `plugins/`, NO `.claude-plugin/`, NO `marketplace.json`/`plugin.json`.
- **Global rules:** `~/.claude/CLAUDE.md` `@import`s from `~/code/schnapp-os/rules/global/` (7 lines).
  No plugin delivers them (rules were never plugin-delivered — only the path moved).
- **Hooks:** wired in `.claude/settings.json` against `${CLAUDE_PROJECT_DIR}/hooks/*.sh`; all 6 fire
  (SessionStart gate incl. its retargeted `scripts/` internal deps, PostToolUse secret-scan +
  shellcheck, UserPromptSubmit capture-nudge, Stop push-gate, SessionEnd backup — all verified).
- **CI:** `freshness` + `ci-lint` GREEN on all 5 code commits.
- **THIS Mac's owner gate: DONE** (main checkout pulled to `main`, `~/.claude/CLAUDE.md` repointed,
  plugin uninstalled, user-scope `enabledPlugins`+`extraKnownMarketplaces.schnapp-os` removed, both
  launchd plists re-rendered off `plugins/core/scripts/`).

## Owner action OWED on EVERY OTHER machine (per-machine, one-time; the flatten lands per machine)
When each other machine next pulls `main`, run (order matters — pull first so `rules/global/` exists):
```
cd ~/code/schnapp-os && git pull
sed -i '' 's|plugins/core/rules/global/|rules/global/|g' ~/.claude/CLAUDE.md
claude plugin list | grep schnapp    # eyeball, then:
claude plugin uninstall schnapp-os-core@schnapp-os
# remove "schnapp-os-core@schnapp-os":true from enabledPlugins and the extraKnownMarketplaces.schnapp-os
#   block in ~/.claude/settings.json
# re-render + reload the 2 launchd plists (recipe: scheduled-tasks/README.md)
```
Until a machine does this, its `@import` breaks on pull and its sessions double-load. (`claude plugin
uninstall` is effectively permanent — the marketplace manifest is deleted, so no reinstall from here.)

## Follow-ups carried forward (NOT Phase-2-blocking)
- **(from Phase 1)** vault working-tree auto-commit; USER-scope `autoMemoryDirectory` → vault on other
  machines; prune stale `~/code/obsidian-vault`.
- **`ci-lint.yml` now vestigial:** it runs `scripts/check-memory-frontmatter.sh memory`, but `memory/`
  was removed from schnapp-os in Phase 1 → validates 0 facts (green-but-vestigial; the vault has its
  own `vault-freshness.yml`). Remove or repurpose during the Phase 4 `PLAN.md`/cleanup pass.
- **`check-op-refs` WARN** on a markdown `[^...]` footnote artifact (pre-existing, WARN-only, exit 0).

## Next: Phase 3, 4, or 5 (sequencing 1 → (2 ∥ 4) → 3 → 5; Phases 1+2 now done)
Read [the plan](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) +
[the spec](../docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md). Generate step-level
detail at the start of the chosen phase.
- **Phase 4 — context/reference discipline** *(independent; recommend next)*. Add the writing-style
  standard as `rules/global/writing-style.md` (+ the `~/.claude/CLAUDE.md` `@import` list +
  `templates/user-global-CLAUDE.md`); reconcile `PLAN.md` (677 lines, now DOUBLY stale — legacy +
  post-flatten) per ADR-0022 precedent; add a soft length-advisory; light-archive old handoffs.
- **Phase 3 — enforcement gates** *(unblocked: needs vault CI + flatten, both done)*. Malformed-secret
  byte-check (TDD) at the rotate/store path; loop rewire (≥2 same-class → drafted gate, not prose);
  extend `last-verified` coverage.
- **Phase 5 — Cowork two-way handoff** *(unblocked: needs vault as shared store, done)*. Connector
  vault access; handoff-packet convention; Code↔Cowork round-trip.

## Operating flow (unchanged)
main-only, subagent-driven (`superpowers:subagent-driven-development`), commit + push each task from
the worktree (`git push origin HEAD:main`, rebase first), flip the plan box + PROGRESS line in the
same push. Secrets are `op://` refs. Instruction files use the writing-style standard. Live status =
[the plan doc](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) / [PROGRESS.md](../PROGRESS.md),
not this snapshot.
