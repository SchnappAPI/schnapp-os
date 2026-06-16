# 0008 — Obsidian MCP: bless the Mac-hosted server, single-source it (Option A)

Date: 2026-06-16. Status: DECIDED + EXECUTED.

## Context
An infra session (2026-06-16, a claude.ai chat in another project — not logged anywhere durable)
relocated the vault to OneDrive and stood up a **new Mac-hosted FastMCP** Obsidian server
(`~/obsidian-mcp/server.py`, port 8767, OAuth 2.1+PKCE+DCR) at `https://obsidian-mcp.schnapp.bet/mcp`.
This diverged from the plan, which specified the Mac-INDEPENDENT, GitHub-served Render connector
already built at `connectors/obsidian-mcp/` (Node/TS, never deployed). The divergence carried no
decision record — the gap this file closes. The original rationale could not be recovered (the
Jun 16 chat is unexported / out of project scope); the likely driver is that the brain/inbox
integration (`inbox_drop` → FSEvents → classifier) is inherently Mac-resident.

## Decision (Option A)
Bless the Mac-hosted server as canonical; do NOT revert to the Render design.
- **Why A over reverting:** the Mac server does strictly more (brain/inbox); the Mac is always-on
  infra, so "Mac off" is already whole-system-degraded; the plan's locked guarantee for *knowledge*
  is "always-complete via **fallback**" (not full Mac-independence — that was scoped to *credentials*,
  Part 4); a second read-only server would be the duplication this rebuild exists to kill.
- **Single source of truth (the fix):** the live source now lives in the repo at
  `connectors/obsidian-mcp/server.py`; the Mac runs it via symlink (`~/obsidian-mcp/server.py` →
  repo), launchd plist unchanged. Edit in repo → restart service to deploy.
- **Retired:** the Render/TS implementation (removed from the tree; recoverable in git history).
- **Fallback when the Mac is off:** the GitHub `obsidian-vault` mirror (obsidian-git push
  re-enabled 2026-06-16) + this repo's `memory/` + `decisions/`. Documented in the `docs-lookup` skill.

## Tradeoff accepted
Off-Mac vault access now requires the Mac powered on (a regression vs the Render design), mitigated
by the documented fallback. Authoritative runtime/infra detail: `schnapp-bet` `docs/CONNECTIONS.md`.

## Consequence / guardrail
A significant architecture change reached production with no decision logged and no push (vault +
CONNECTIONS.md sat unpushed). Prevention: the session-start gate now also checks satellite repos
(`schnapp-bet`, `obsidian-vault`) for unpushed/unmerged work.
