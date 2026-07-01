# Handoff 044 — Phase 1 (vault stand-up) COMPLETE; resume point = Phase 2 or 4

**Date:** 2026-07-01. **Surface:** Claude Code on the Mac, Opus 4.8, subagent-driven.
**Status:** schnapp-os streamline **Phase 1 DONE + verified end-to-end**. This handoff carries the
NEW current-state map (verify against it, do not reconstruct) and the next-phase resume point.

## What Phase 1 delivered (all on `main`, all verified)
- **Two-repo split, Fork A.** The Obsidian vault repo `SchnappAPI/obsidian-vault` was renamed to
  **`SchnappAPI/schnapp-vault`** (private) and cloned to **`~/code/schnapp-vault`** (git-native, OUT
  of OneDrive). It IS the Obsidian vault AND now holds the memory lane.
- **Memory migrated + normalized.** All 12 facts folded into `schnapp-vault/memory/` and normalized to
  ONE flat 8-key schema (`name, description, type, area, source, created, updated, superseded`).
- **Schema single-defined + CI-enforced.** Vault `agents.md` is the ONLY schema definition site.
  `scripts/check-frontmatter.sh` (greps the FLAT keys = the dead-check FIX) runs as `vault-freshness.yml`
  on push/PR. Green.
- **All consumers repointed to the vault:** obsidian-mcp (`connectors/obsidian-mcp/server.py`, live via
  the `~/obsidian-mcp/server.py` symlink), the Brain Agent (in-vault `.github/scripts`, dynamic
  `parents[2]`), the `com.schnapp.brain-watcher.plist`, the `~/Documents/Obsidian` symlink, and
  **memory-mcp** (Render `MEMORY_REPO`=`SchnappAPI/schnapp-vault`; token `SCHNAPP_OS_PAT` given vault R/W).
- **schnapp-os no longer owns `memory/`.** The memory SYSTEM PROCEDURES moved to
  [`docs/memory-lane.md`](../docs/memory-lane.md); `autoMemoryDirectory` (project + user scope on this Mac)
  points at `~/code/schnapp-vault/memory`.
- ADR: [decisions/0023](../decisions/0023-two-repo-vault-split-flat-memory-schema.md).

## Current-state map (VERIFIED 2026-07-01 — verify, don't reconstruct)
- **Repos (SchnappAPI/):** `schnapp-os` (system); `schnapp-vault` (private, = vault + memory);
  `obsidian-vault` name now redirects to `schnapp-vault`.
- **Vault:** `~/code/schnapp-vault` (git-native). OneDrive `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian`
  and `~/code/obsidian-vault` are inert COLD BACKUPS (nothing writes to them; not deleted).
- **Memory:** global lane = the vault; schema in vault `agents.md`; procedures in `docs/memory-lane.md`.
  memory-mcp (Render `memory-mcp-rtad`) serves it off-Mac. `autoMemoryDirectory` → vault (both scopes, this Mac).
- **Services:** obsidian-mcp (launchd, :8767) + brain-watcher (launchd) both healthy on the vault path.

## Follow-ups carried forward (NOT Phase-1-blocking)
1. **Vault working-tree auto-commit.** obsidian-mcp + Obsidian write the vault working tree but do NOT
   git-commit, so git truth lags Obsidian edits (breaks "git = one truth" for Obsidian writes). The vault
   needs an auto-commit/push mechanism (as memory-mcp has). Design it in a later phase.
2. **USER-scope `~/.claude/settings.json` `autoMemoryDirectory`** → `~/code/schnapp-vault/memory` on EVERY
   OTHER machine (done on this Mac). One-liner per machine.
3. **Prune `~/code/obsidian-vault`** (stale clone; the gate-2 spec's clean-only guard skipped it because it
   had 2 uncommitted Inbox deletions). Manual `rm -rf` when convenient.

## Next: Phase 2 or Phase 4 (either order; sequencing 1 → (2 ∥ 4) → 3 → 5)
Read [the plan](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) (Phases 2-5 are outlines;
generate step-level detail at the start of that phase) + [the spec](../docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md).
- **Phase 2 — flatten the plugin → native `.claude/`.** Move `plugins/core/{skills,commands,agents,rules,scripts,hooks}`
  to native `.claude/` + top-level; delete `marketplace.json` + `plugin.json`; uninstall the cached
  `schnapp-os-core@schnapp-os` plugin; retarget ~20 live docs + `settings.json` hook paths. Owner gate:
  per-machine `~/.claude/CLAUDE.md` `@import` edit + uninstall cached plugin. Resolves decisions/0011 #2.
- **Phase 4 — context / reference discipline.** Add the writing-style standard as `rules/global/writing-style.md`
  (+ the `@import` list); reconcile `PLAN.md` (677 lines) the way PROGRESS.md was (ADR-0022 precedent);
  add a soft length-advisory; light-archive old handoffs.

## Operating flow (unchanged)
main-only, subagent-driven (superpowers:subagent-driven-development), commit + push each task from the
worktree (`git push origin HEAD:main`, rebase first), flip the plan box + PROGRESS line in the same push.
Secrets are `op://` refs. Instruction files use the writing-style standard. Live status =
[PLAN doc](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) / [PROGRESS.md](../PROGRESS.md),
not this snapshot.
