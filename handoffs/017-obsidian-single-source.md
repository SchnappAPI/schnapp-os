# Handoff 017 — Obsidian MCP single-sourced (Option A executed). Part 10 still NEXT.

Date: 2026-06-16. Surface: claude.ai web (edits via Schnapp Mac connector).

## TL;DR
Resolved the Obsidian architecture deviation. The live Mac-hosted server is now the canonical,
single-sourced off-Mac MCP, its source lives in the repo, the Render/TS implementation is retired,
the stale GitHub mirror is fixed, and the divergence is finally logged (decisions/0008). Capability
layer + Parts 0-9 unchanged. **Part 10 (package + wire surfaces) remains the next planned work.**

## Done this session
- **Mirror fix:** pushed the vault's 15 unpushed commits (obsidian-vault now current). Root cause was
  obsidian-git `"disablePush": true` (not auth); flipped to false (backup saved). NOTE: Obsidian was
  running, so the flip needs an Obsidian reload / GUI confirm to activate and not be overwritten.
- **Option A (single source of truth):** `~/obsidian-mcp/server.py` imported to
  `connectors/obsidian-mcp/server.py` as canonical; the Mac runs it via symlink
  (`~/obsidian-mcp/server.py` -> repo), **launchd plist untouched** (lowest risk). Render/TS files
  removed (git history retains them). `.env.template` (op:// ref) + `.gitignore` (runtime artifacts) +
  rewritten README added. Service restarted + verified: running, 401 OAuth, functional search ok.
- **decisions/0008** logged — blesses Mac-hosted, records the single-source fix, the accepted Mac-
  dependency tradeoff, the fallback, and the prevention guardrail. Closes the unlogged-divergence gap.
- **Prevention:** `session-start-gate.sh` now checks satellite repos (`schnapp-bet`, `obsidian-vault`)
  for unpushed commits (the lapse that hid both this session). Unpushed-only, existence-guarded.
- Living docs updated: `docs-lookup`, `memory/obsidian-state.md`, PLAN 6.2 (->[x]) + owner-gated line.
  CATALOG unchanged; freshness green.

## Divergence rationale — NOT recoverable
The Jun 16 infra session was a claude.ai chat in another project. Not on the Mac as a Code transcript
(newest is Jun 8), not in the vault's Claude Export (stops May 22), not reachable via this project's
chat search (empty/new project). If the reason is wanted on record, export/paste that chat. Likely
driver (inference): the brain/inbox integration is inherently Mac-resident.

## Deploy model (remember this)
Edit `connectors/obsidian-mcp/server.py` in the repo, push, then restart to deploy:
`launchctl kickstart -k gui/$UID/com.schnapp.obsidian-mcp`. Runtime artifacts (venv, oauth_state.json,
logs) stay on the Mac, gitignored. Authoritative infra detail: `schnapp-bet` `docs/CONNECTIONS.md`.

## Remaining (owner-gated)
- Reload Obsidian (or toggle obsidian-git "Disable push" off) so the push flip sticks.
- Retire the redundant `~/code/obsidian-vault` clone (confirm before deleting).
- Carried: `~/.git-credentials` plaintext cleanup (handoff 015 #1).

## Next session
Part 10 — package the marketplace plugin (`.claude-plugin/marketplace.json` +
`plugins/core/.claude-plugin/plugin.json`), deliver the global gate+push-gate via
`${CLAUDE_PLUGIN_ROOT}`, strip those two from project settings.json keeping only the backup (explicit
owner approval), then wire Cowork/claude.ai/iPhone. Then Part 11, then the 14-point sweep.
