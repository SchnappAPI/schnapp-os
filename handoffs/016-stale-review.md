# Handoff 016 — Repo stale-review (Obsidian cluster reconciled). Part 10 still NEXT.

Date: 2026-06-16. Surface: claude.ai web (hookless; edits via Schnapp Mac connector, single commit).

## TL;DR
A review session, not a Part. Reconciled the repo against **verified Mac ground truth** after the
infra session. The Capability layer (C.0–C.3) and Parts 0–9 are unchanged; **Part 10 (package +
wire surfaces) is still the next planned work.** No plan steps were advanced or flipped.

## What was stale and why
The infra session relocated the Obsidian vault and stood up a **new Mac-hosted** Obsidian MCP, but
the repo still described the **old, undeployed Render** design. Root cause of the GitHub-vs-reality
gap: schnapp-bet `docs/CONNECTIONS.md` was committed locally (`b7d318d`) but **never pushed**
(`[ahead 1]`) — so the authoritative infra doc on GitHub was the 2026-05-27 version.

## Done this session
- **Pushed** schnapp-bet `b7d318d` → `docs/CONNECTIONS.md` (with full Obsidian MCP + Brain Agent +
  GitHub MCP entries, verified 2026-06-16) is now live on GitHub. schnapp-bet back in sync.
- **`docs-lookup` SKILL** — off-Mac row + workflow corrected: live connector `obsidian-mcp.schnapp.bet`
  with real tools `search_notes`/`read_note`/`list_notes` (was the non-existent `vault_search`/`vault_read`
  on the undeployed Render connector). Added the Mac-dependency caveat + fallback. Mac row was already
  correct (npm `obsidian`: `search-vault`/`read-note`/`list-available-vaults`, verified).
- **`connectors/obsidian-mcp/{README,DEPLOY}.md`** — SUPERSEDED (2026-06-16) banners. Kept (not deleted)
  because it is the Mac-INDEPENDENT design; the live Mac-hosted server is not.
- **`backup-archive.sh`** — `OBSIDIAN_VAULT_DIR` default → `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian`
  (canonical). Behavior-neutral today (the old `~/Documents/Obsidian` default is a symlink to it) but robust.
- **PLAN.md** — 6.2/6.3 + owner-gated-tracks got dated **UPDATE** clauses (record preserved, not rewritten).
- **memory/** — new `obsidian-state.md` (durable topology fact, points to CONNECTIONS.md) + index line.
- **PROGRESS.md** — dated session entry appended.
- CATALOG unchanged; freshness gate green. Handoffs 002–015 and prior PROGRESS lines left intact (record).

## Verified ground truth (for the next session)
- Canonical vault: `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian`; `~/Documents/Obsidian` = symlink.
- Off-Mac obsidian MCP: `~/obsidian-mcp/server.py`, port 8767, OAuth 2.1+PKCE+DCR, `obsidian-mcp.schnapp.bet`,
  7 tools (`read_note`,`write_note`,`append_note`,`search_notes`,`list_notes`,`inbox_drop`,`get_index`).
- Mac Code: npm `obsidian` stdio MCP → `~/Documents/Obsidian`.
- Authoritative infra reference (now current on GitHub): schnapp-bet `docs/CONNECTIONS.md`.

## Open / flagged for owner (NOT actioned — genuine decisions)
1. **Single-source-of-truth gap:** the live `~/obsidian-mcp/server.py` lives only on the Mac, not in any
   repo. Decide: import it (where? it carries brain-agent/inbox concerns that may belong elsewhere), or
   leave it out deliberately.
2. **Mac-dependency regression:** off-Mac obsidian now needs the Mac on. The locked plan wanted Mac-independent
   off-Mac access (the superseded Render connector delivered that). Decide: accept, or restore GitHub-served.
3. Retire the superseded `connectors/obsidian-mcp` (only after #1/#2) and the redundant `~/code/obsidian-vault`
   clone. Carried from 015: `~/.git-credentials` plaintext cleanup.

## Gotcha discovered this session
- The **Schnapp Mac `write_file` tool OVERWRITES** (truncates) — it does not append. For appends use
  `shell_exec` with `cat >> file <<'EOF'`. (Caught + restored PROGRESS.md from git mid-session.)

## Next session
Resume **Part 10** per handoff 015's resume prompt (package the marketplace plugin; deliver the global
gate+push-gate via `${CLAUDE_PLUGIN_ROOT}`; strip those two from project settings.json keeping only the
backup, with explicit owner approval; then wire Cowork/claude.ai/iPhone). Recommend resolving open item #1/#2
above before/at packaging so the plugin ships a coherent obsidian story.
