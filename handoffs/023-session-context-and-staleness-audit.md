# Handoff 023 — full session context + repo staleness audit (resume point)

Date: 2026-06-16. Surface: claude.ai web (via Schnapp Mac + GitHub connectors). Status: COMPLETE.
This file is the single source of context for everything done in this session, written so a fresh
chat or Code session loses nothing. Read it first on resume.

## What this session did (4 phases, newest last)
1. **mac-mcp slow-restart fix** (handoffs 020->021, decision 0010). Fixed the :8765 restart bind
   race in all three custom MCP connectors. Two layers: graceful `launchctl kill TERM` (not
   `kickstart -k` SIGKILL) + a pre-bound reuse socket served via
   `uvicorn.Server(uvicorn.Config(app,host,port)).run(sockets=[sock])`. mac-mcp rebind ~2 min -> ~2.5s.
2. **Optimization pass** (decision 0010 "Refinement"). Dropped `SO_REUSEPORT`, kept `SO_REUSEADDR`
   (REUSEADDR alone fixes the race under graceful TERM and preserves loud-fail on accidental
   double-run; REUSEPORT allowed silent split-brain — verified empirically). Rewrote the `service_restart`
   MCP tool to default to graceful TERM (`mode='hard'` for kickstart -k; self-verify + kickstart
   fallback for non-KeepAlive agents). `flask_restart` left on kickstart -k (out of scope).
3. **Part 10.1 PREP** (handoff 022). Authored `.claude-plugin/marketplace.json` (marketplace
   "claude-kit", plugin "claude-kit-core", source ./plugins/core) + `plugins/core/.claude-plugin/
   plugin.json`. Executed decision 0005's hook split: stripped SessionEnd from the plugin
   `hooks.json` so the plugin delivers ONLY the global SessionStart gate + Stop push-gate; backup
   stays project-scoped. Install/de-dup/verify deferred to Code (handoff 022).
4. **Part 10.2 PREP**. Authored `surfaces/always-loaded-instructions.md` (canonical hookless
   always-loaded block) + appended per-surface "Enablement" checklists to
   surfaces/{claude-ai-web,iphone,cowork}.md.
5. **This staleness audit** (handoff 023). Ran the repo's own freshness gate + swept for stale
   references to everything changed; fixed the live-doc stragglers (below).

## Audit results (verified as fact, not assumed)
Method: ran `plugins/core/scripts/check-freshness.sh` (the CI gate) + targeted greps across all
.md/.json/.yml, distinguishing append-only HISTORY (handoffs, decisions, PROGRESS, memory logs —
left intact) from LIVE current-state docs (fixed where stale).

VERIFIED CURRENT (no change needed):
- `plugins/core/CATALOG.md` — freshness gate green (regenerated + diff clean).
- Component counts 22 skills / 2 agents / 4 commands — match reality exactly.
- No `node_modules` tracked in git (op-mcp/.gitignore correct; 16 tracked source files only).
- `SO_REUSEPORT` appears only in code comments (as "intentionally NOT set") + history logs + 0010.
- op-mcp host = Render + Cloudflare OAuth portal (`mcp.schnapp.bet`), NOT Mac/Fly — matches
  DEPLOY.md, decision 0004, credentials-map.md, memory/credentials-state.md. (`mcp.schnapp.bet`
  is absent from the Mac cloudflared config; /health 404 is the OAuth front. Verified, not assumed.)
- Root README is deliberately status-free (points to PLAN/PROGRESS); templates clean.
- handoffs 000-022 + decisions 0001-0010 continuous, no gaps.
- credentials-state.md (memory) + credentials-map.md both current (op + gh work; op-mcp live).

FIXED this audit (live docs that had gone stale vs decision 0010 / reality):
- connectors/{mac,github,obsidian}-mcp/README.md — recovery command `kickstart -k` -> graceful
  `launchctl kill TERM ... (decision 0010)`. (anti-stale class fix: all three.)
- connectors/op-mcp/README.md — stopped calling Fly.io "recommended"; Render is the chosen host.
- PLAN.md 4.1 — added a DONE annotation (SA rotated; op/gh work) so the [x] task's old "are down"
  text is not misread as current state.
- PLAN.md 10.1 + 10.2 — [ ] -> [~] PARTIAL with annotations (manifests authored / enablement
  drafted this session; install + apply pending). Tracker-currency.
- .claude-plugin/marketplace.json — removed the hardcoded "22 skills, 4 commands, 2 agents" count
  (CATALOG is the source of truth; prevents future staleness).

FLAGGED, NOT changed (owner judgement; both current + consistent, so not "stale"):
- credentials-state.md (memory) and credentials-map.md overlap heavily. Both agree and are current,
  but it is duplication (an anti-stale smell). Consolidating is a refactor with risk; left for owner.
- GitHub Actions `OP_SERVICE_ACCOUNT_TOKEN` still NOT on `DB_Storage` + `appfolio-marketing-project`
  (never scoped; master-token-spread concern). Tracked open item in both credential docs.
- `flask_restart` still uses `kickstart -k` (Flask SIGTERM handling unverified; out of scope).
- The live `service_restart` graceful path is deployed + code-verified but was not runtime-tested
  through the tool (the call is approval-gated; one approved call would confirm the self-verify/
  fallback branch).

## Current repo state
- Both repos clean + pushed. claude-kit latest commit is this audit; schnapp-bet last touched for
  CONNECTIONS.md (decision 0010). `git rev-list --left-right --count @{u}...HEAD` = 0/0 on both.
- Deps PINNED (decisions 0008/0009): do NOT bump mcp/uvicorn/starlette/pydantic. mcp 1.27.2.
- All three custom MCP connectors live + healthy on the Mac (graceful-restart + REUSEADDR socket);
  github 8766, obsidian 8767, mac 8765.

## Next actions (in order)
1. **Run handoff 022 on a Claude Code session on Schnapps-MBP** — installs the claude-kit-core
   plugin, verifies gate+push-gate fire in an unrelated repo, de-dups project settings.json
   (keep only SessionEnd backup), verifies no double-fire. Closes PLAN 10.1 + 7.2. (That session
   writes handoffs/024.)
2. **Apply Part 10.2 enablement** (owner action in each client UI): per
   surfaces/{claude-ai-web,iphone,cowork}.md — enable connectors/skills, paste
   surfaces/always-loaded-instructions.md into claude.ai Project instructions + Cowork, connect the
   repo in Cowork. Depends on 10.1.
3. **Part 10.3** — run PLAN.md "Final verification" (14 items) against the whole system.
4. **Part 11** (capstone, authorable now): scheduler routines, `/do` orchestrator, `status`
   control plane. PLAN.md Part 11.

## Key facts / gotchas
- THIS surface is claude.ai web. The Mac is reached via the `mac-mcp` connector
  (`mac-mcp.schnapp.bet` -> com.schnapp.macmcp:8765). Restarting mac-mcp severs the channel — restart
  it only via a detached double-fork daemon (see 020/021), never a foreground tool call.
- Persist writes via the GitHub connector or a generated Code prompt. Run the session-hygiene skill
  at start + wrap (no hooks on this surface).
- Authoritative infra doc: schnapp-bet/docs/CONNECTIONS.md. Pinned-dep + single-source-symlink
  rules: decisions 0008/0009. Hook-delivery split: decision 0005.
