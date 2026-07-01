# Handoff 046 — Phase 4 (context / reference discipline) COMPLETE; resume = Phase 3

**Date:** 2026-07-01. **Surface:** Claude Code on the Mac, Opus 4.8, subagent-driven.
**Status:** schnapp-os streamline **Phase 4 DONE + verified**. Phases 1, 2, 4 complete; **Phase 3 is
next** (then Phase 5). This handoff carries the new current-state map (verify against it).

## What Phase 4 delivered (all on `main`, CI green on every commit)
- **Writing-style rule.** `rules/global/writing-style.md`: the instruction-file writing standard (terse
  imperative, no em dashes, reference-not-restate, one-screen, concrete, every-line-earns). It was
  referenced across plan + spec but never defined. De-duped `working-style.md`'s writing mechanics into
  it (working-style now delegates). Wired the `@import`: 7 -> 8 global rules. (T1 `ad8b2e9`)
- **PLAN.md retired.** 677 lines -> a 25-line pointer + verbatim archive
  (`docs/archive/PLAN-archive-2026-07-01.md`) + ADR [0025](../decisions/0025-plan-md-retired-to-pointer.md).
  Live planning is per-initiative under `docs/superpowers/plans/`; status = `PROGRESS.md`. (T2 `abd82c7`)
- **Length-advisory.** `hooks/length-advisory.sh`: PostToolUse WARN, never blocks (always exit 0), when
  an always-load `rules/global/*.md` (> 50 lines) or a `rules/` module / repo `CLAUDE.md` (> 120)
  grows too long. TDD test + CI self-test. (T3 `34fc1ec`)
- **Handoff index.** Generated + CI-gated: `scripts/gen-handoff-index.sh` -> `handoffs/README.md`, 46
  entries newest-first, newest marked the resume point. NO files moved (30 docs link handoffs by path).
  (T4 `1b2c5f8`)
- **Review-fix (Opus whole-branch).** Caught the "fix the class, not the instance" miss: cleared ~35
  stale `PLAN.md`/`Part-N` provenance locators, the always-load "flip the PLAN.md box" instructions
  (`anti-stale.md` etc. now say the per-initiative plan-doc box, matching ADR 0025), the `7 -> 8` count
  in front-door docs, and README + `surfaces/` content that still described the removed marketplace
  plugin as the current hook-delivery mechanism (Phase-2 fallout invisible to the `plugins/core` grep).
  (`9ceb382`)

## Current-state map (VERIFIED 2026-07-01 on THIS Mac)
- **8 global rules** in `rules/global/` (writing-style.md added, `@import`ed here). CATALOG lists it.
- **PLAN.md = a 25-line pointer**; the original 11-Part build is archived. Live plans in
  `docs/superpowers/plans/`; status in `PROGRESS.md`; decisions in `decisions/`.
- **Length-advisory** is the 3rd PostToolUse hook (after secret-scan, shellcheck); it never blocks.
- **Handoff index** generated + gated by `check-freshness.sh` (fails CI if CATALOG OR the index drifts).
- No live doc commands "flip the PLAN.md box" or describes the removed plugin as current; 0 stale
  `Part-N` locators outside the archive + the repo-review docs' own section headers.

## Owner action owed on EVERY OTHER machine (per-machine, additive, low-risk)
Add one line to `~/.claude/CLAUDE.md` after the `speed-by-default.md` @import:
```
@~/code/schnapp-os/rules/global/writing-style.md
```
Done on this Mac. (Still also owed from Phase 2, per handoff 045: the flatten gate — `~/.claude/CLAUDE.md`
rules/global repoint, plugin uninstall, settings entries, plist re-render — and the vault
`autoMemoryDirectory` one-liner.)

## Follow-ups carried forward (NOT blocking)
- **`ci-lint.yml` vestigial:** runs `scripts/check-memory-frontmatter.sh memory` against a `memory/`
  dir Phase 1 removed (0 facts, green-but-vestigial; the vault has its own gate). Remove or repurpose.
- **`backup-archive.sh`** still mirrors a `memory/` subdir that moved to the vault (guarded by
  `[ -d ]`, harmless) and its README prose mentions it: cosmetic Phase-1 residue.
- **(Phase 1)** vault working-tree auto-commit; prune stale `~/code/obsidian-vault`.

## Next: Phase 3 — enforcement gates (UNBLOCKED: needs vault CI + flatten, both done)
Read [the plan](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) (Phase 3) +
[the spec](../docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md) §4. Generate
step-level detail at the start. Tasks: malformed-secret byte-check gate (TDD) at the rotate/store path
(`op read <ref> | xxd` compares stored bytes to expected; `rotate-secret` grows a verify step); loop
rewire (learning-worker counts error-class frequency, on >=2 same-class drafts a gate as a PR/issue
instead of another prose fact); extend `last-verified` coverage in `freshness.yml`; ADR. Then Phase 5
(Cowork two-way handoff).

## Operating flow (unchanged)
main-only, subagent-driven (`superpowers:subagent-driven-development`), commit + push each task from
the worktree (`git push origin HEAD:main`, rebase first), flip the plan-doc box + PROGRESS line in the
same push. Secrets are `op://` refs. Instruction files follow `rules/global/writing-style.md`. Live
status = [the plan doc](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) / [PROGRESS.md](../PROGRESS.md).
