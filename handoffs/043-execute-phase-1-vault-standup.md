# Handoff 043 — Execute Phase 1 (vault stand-up), subagent-driven

**Date:** 2026-06-30. **Surface:** fresh session, owner intends **Opus 4.8**.
**Execution model:** subagent-driven — orchestrator DRIVES, one fresh subagent per task, two-stage review between tasks. Use `superpowers:subagent-driven-development`.
**Resume point for:** executing **Phase 1** of the schnapp-os streamline. Design is DONE and on `main`; this is build, not design.

---

## Read first (canonical — do not re-derive)
1. [docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md](../docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md) — the phased plan. **Phase 1 is the job.**
2. [docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md](../docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md) — the design + rationale.
Both were pushed to `main` at `b283b51`. Pull `main` before starting.

## The design in one breath (detail is in the spec)
- **Priorities:** ACCURATE #1 (freshness = its engine), then Consistent, Global, Quick.
- **Principle:** move load-bearing knowledge from SHELF to GATE.
- **Two-repo split on the atomicity line:** `schnapp-os` = system + system-state; new PRIVATE `schnapp-vault` = cross-surface knowledge (= the Obsidian vault).

## Phase 1 deliverable
`schnapp-vault` exists (private, `~/code/schnapp-vault`, = the Obsidian vault), `memory/` migrated + normalized to ONE flat schema, vault CI gate live (the dead supersede-check FIXED against the flat key), MCPs repointed. Plan lists 10 tasks — follow them in order.

## STOP-and-confirm gates (hard-to-reverse — get owner go BEFORE each)
1. **Create the GitHub repo** (`schnapp-vault`, private, owner account).
2. **Move the Obsidian vault OUT of OneDrive** to `~/code/schnapp-vault` — a git tree inside OneDrive corrupts; this touches owner filesystem + OneDrive state.
3. **Repoint `memory-mcp` + `obsidian-mcp`** at the vault (running services).
Everything else (schema normalization, CI script, doc updates) proceeds without pausing.

## Watch-outs (from the 2026-06-30 audit — do not re-break)
- **Fix the supersede-check by making the schema FLAT** — nested `metadata:` is exactly why the old check was dead code (grepped a top-level key that files indented). Flat keys, deterministically parseable.
- **Schema single-definition site = vault `agents.md`.** README + memory-write instructions REFERENCE it, never restate — 3 schema-truth sources caused the drift.
- **`agents.md` is NARROW** — the vault's read/write contract only; system behavior stays in schnapp-os.
- **Vault git tree must NOT sit under any cloud-sync path** — git is the only sync engine.
- Add missing `updated:` = each fact's last git-commit date. Set `source:`, `superseded: false`.

## Git / operating flow
- **main-only, commit + push each task.** From a worktree, land via `git push origin HEAD:main` (fast-forward); pull/rebase before push. Every state-changing commit flips a PLAN box + appends a PROGRESS line in the SAME commit.
- Secrets are `op://` references, never values. Instruction files use the writing-style standard.
- Phase 1 task 10 writes the first ADR (two-repo split + git=one-truth + vault-out-of-OneDrive) and flips trackers.

## Next
Confirm with owner, then start Phase 1 task 1 (create `schnapp-vault`). Live status: [PLAN.md](../PLAN.md) / [PROGRESS.md](../PROGRESS.md), not this snapshot.
