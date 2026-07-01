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

## Current-state map (VERIFIED on the Mac by the Phase-1 probe, 2026-07-01 — VERIFY against this, do NOT reconstruct it)
Confirm on resume; correct if any line is wrong. Handed to you so you never rebuild the map.
- **Repos (all `SchnappAPI/`):** `schnapp-os` (this); `schnapp-vault` (created 2026-07-01, PRIVATE, EMPTY, not yet cloned); `obsidian-vault` (the actual git-backed Obsidian content).
- **Clones of `obsidian-vault`:** OneDrive `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian` (canonical — owner opens this); `~/code/obsidian-vault` (satellite). `~/code/schnapp-vault` does NOT exist yet.
- **Memory lane:** currently `schnapp-os/memory/`; schema = NESTED `metadata:` (`node_type/scope/source/updated/supersedes`), inconsistent (some miss `description`/`type`/`updated`). Target = FLAT §3.5. This IS the normalization delta.
- **Services / MCP:**
  - `memory-mcp` = Render-hosted (`memory-mcp-rtad.onrender.com`), git-backed via GitHub API; code `connectors/memory-mcp/`. Repoint = Render service-config (owner-side), NOT a local edit.
  - `obsidian-mcp` = LOCAL launchd, `/Users/schnapp/obsidian-mcp/server.py`, port 8767, vault path HARDCODED to the OneDrive folder.
  - **Obsidian Brain Agent** (inbox watcher) ALSO hardcodes the OneDrive path.
- `gh` authed as `SchnappAPI`.

## Deltas the probe caught (this plan's Phase-1 task list predates the map — treat it as intent, re-cut the concrete tasks)
1. The vault ALREADY EXISTS (`obsidian-vault`, 2 clones). "Create schnapp-vault" → really CONSOLIDATE (see OPEN FORK).
2. OneDrive-exit touches THREE hardcoded consumers together: `obsidian-mcp` (8767), the Brain Agent, the OneDrive clone. Repoint all or break them.
3. Gate 3 SPLITS: `obsidian-mcp` = local launchd edit; `memory-mcp` = Render config (owner-side).

## OPEN FORK — resolve with owner BEFORE any irreversible step
Consolidate to ONE vault repo:
- **(A, recommended)** Rename existing `obsidian-vault` → `schnapp-vault`, delete the empty new one, fold the memory lane in. Preserves content + history + working clones; least migration.
- **(B)** Migrate `obsidian-vault` content + memory into the new empty `schnapp-vault`, retire `obsidian-vault`. More moving of Obsidian content + clone re-pointing.
After the owner picks, RE-CUT the Phase-1 tasks against the map above, THEN execute the gates.

## Rule this handoff now honors (the lesson — do not repeat the violation)
A handoff carries established FACTS (the current-state map), NOT just decisions. VERIFY against the map; never RECONSTRUCT it. Handing decisions without the map forces the exact rediscovery this system exists to kill.

## Git / operating flow
- **main-only, commit + push each task.** From a worktree, land via `git push origin HEAD:main` (fast-forward); pull/rebase before push. Every state-changing commit flips a PLAN box + appends a PROGRESS line in the SAME commit.
- Secrets are `op://` references, never values. Instruction files use the writing-style standard.
- Phase 1 task 10 writes the first ADR (two-repo split + git=one-truth + vault-out-of-OneDrive) and flips trackers.

## Next
Confirm with owner, then start Phase 1 task 1 (create `schnapp-vault`). Live status: [PLAN.md](../PLAN.md) / [PROGRESS.md](../PROGRESS.md), not this snapshot.
