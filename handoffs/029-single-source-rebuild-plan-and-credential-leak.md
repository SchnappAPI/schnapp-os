# Handoff 029 — single-source-of-truth rebuild plan + credential-leak response

Date: 2026-06-21. Surface: Claude Code (Mac). Status: **plan APPROVED, execution started (Phase 0 done).**
Blocked on one owner-only action (mint new SA token). Supersedes the narrow reorg framing of handoff 028.

## What happened this session
1. Continued the credential reorg (handoff 028) as a **worktree-style read-only fan-out**: 6 parallel
   agents produced per-item migration dossiers (consumer maps, op_refs, execution checklists).
2. **Discovered a credential leak** mid-grep: `obsidian-vault/Claude Export/Conversations/*.md` (~28
   files) + `Notes/Credentials CLAUDE.md` contain a **plaintext dump of every vault value**, incl. the
   master `OP_SERVICE_ACCOUNT_TOKEN`. Git-tracked + pushed (private `SchnappAPI/obsidian-vault`) +
   OneDrive-synced. **All vault values compromised.** (This session's transcript also caught the dump → sensitive.)
3. Owner expanded scope: from "fix the vault" → **rebuild the whole system as single-source-of-truth**
   (the root pain = same fact in many homes, nothing stops copies → eternal staleness).
4. Brainstormed → grilled → wrote spec → mid-session **environment review** (schnapp-kit/claude-mem/
   extra plugins surfaced) → re-validated → **plan approved** (exited plan mode).

## Canonical docs (read these to resume)
- **Plan (execution roadmap):** `~/.claude/plans/i-am-not-sure-fancy-garden.md`
- **Spec (design):** `docs/superpowers/specs/2026-06-17-single-source-standard-and-credential-rebuild.md`
- **Leak record:** `memory/credential-leak-2026-06-17.md`; **owner prefs:** `memory/owner-working-preferences.md`
- Prior credential design: `docs/superpowers/specs/2026-06-17-credential-system-design.md`; map: `credentials-map.md`

## Locked decisions (from the grill)
- Root authority = **`claude-kit` → rename `schnapp-os`**; harvest `schnapp-kit` (per `decisions/0003`).
  Consolidate `schnapp-kit + claude-skills + ref-vault/claude` into it. One distribution.
- **Reuse-over-build:** doctrine≈`anti-stale.md`; CI≈`freshness.yml`; handoff/agentic-os/cleanse-secrets/
  consolidation-loop exist in schnapp-kit/core → harvest. BUILD NEW only: `rotate-secret`, Registry, `vault-resolve`.
- **Prune = delete-by-default, git is backup, owner approves each deletions list.**
- **Re-sequenced:** Phase 1 SA-rotation → Phase 2 consolidate to schnapp-os → Phase 3 secrets skills+reorg → Phase 4 rules/knowledge/repos.
- Secrets: vault = sole source via op-mcp connector + `vault-resolve`; **hybrid** bootstrap (SA token =
  connector host + primary Mac only); **two PATs** (`GITHUB_PAT` scoped: contents/actions/PRs/issues/checks,
  NO admin/webhooks/delete + `GITHUB_PAT_ADMIN` held back); `SQL_CONNECTION_STRING` drop+derive in
  `schnapp-bet/web/lib/db.ts`; defer DB app-login (document `sa`); Cloudflare API token parked.
- Auto-export of conversations KEPT; add **`cleanse-secrets`** (pre-store redact + retro-scrub 28 files + CI scan).
- Surfaces: MacBook Pro, HP laptop, work desktop, claude.ai, iPhone — all resolve via the connector.
- Competing systems (`claude-mem` + live MCP, disabled plugins) → dispositioned per-item in the consolidation map.

## NEXT ACTION (Phase 1) — blocked on owner mint
**Owner:** 1Password → Developer/Service Accounts → mint a NEW token for the SA (alongside the old →
zero-downtime). Then I propagate (no-echo) + verify + you revoke the old.

**SA propagation targets (already enumerated this session):**
- Shell: `~/.zshrc`, `~/.zshenv` (1 export line each).
- Plist: `~/Library/LaunchAgents/com.schnapp.environment.plist` (sets the var).
- **11 GH repo secrets** `OP_SERVICE_ACCOUNT_TOKEN`: obsidian-vault, schnapp-bet, claude-kit, appfolio-quickbase-sync,
  schnapp-kit, claude-skills, sports-modeling, appfolio-mcp, ref-vault, af-invoice-parser, af-query-api
  (set via `gh secret set` — value via stdin/no-echo). NOTE: update appfolio-quickbase-sync's SECRET too
  (operational; the repo code stays untouched).
- **Render `op-mcp`** env `OP_SERVICE_ACCOUNT_TOKEN` + redeploy (the connector host).
- **Restart after:** `com.schnapp.{macmcp,githubmcp,obsidian-mcp,brain-watcher}` + `bet.schnapp.{web-prod,flask}`
  (rotation gotcha — they cache the old token via `op-wrap.sh`). Verify: `op whoami` / `op_health` / a real `op read`.

## In-flight state (carry)
- Vault items **created** (hold leaked bearer values → rotate to fresh in Phase 3): `MAC_MCP_AUTH_TOKEN`
  (`kxjl5looa4x3fqhuynpqxsdunq`), `GITHUB_MCP_AUTH_TOKEN` (`34kn5t4ryjyyfm2pnj7eiwmbqm`), both tagged `mcp` + noted.
- **Repointed** `connectors/{mac-mcp,github-mcp,obsidian-mcp}/.env.template` (repo) + the deployed
  `~/mac-mcp`, `~/github-mcp`, `~/obsidian-mcp/.env.template`: MCP bearer refs → new items; `GH_PAT` →
  `op://web-variables/GITHUB_PAT/token`; dropped the stale "scoped PAT" comment. Committed this session.
- **NOT yet done:** old items (`MCP Tokens`, `GitHub` bundle) NOT deleted; `claude.yml` / `CONNECTIONS.md`
  doc-refs NOT repointed; services NOT restarted. `GITHUB_PAT/token` DIFFERS from old `pat_*` → verify
  GitHub auth after repoint before deleting the `GitHub` bundle.
- Spawned background tasks: harden hardcoded auth fallbacks (schnapp-bet); prune stale clones (web-bad, sports-modeling worktree).

## Gotchas
- Caveman mode active (terse). Owner prefs: parallelize; small reusable skills; automate (do, don't tell);
  concise; handoffs = primer + file (`memory/owner-working-preferences.md`).
- `op` works in local shell (SERVICE_ACCOUNT). Owner authorized me to do `op item create/edit/delete` via CLI.
- Phase 2 rename needs a **session restart** (moving the dir breaks live rule/plugin paths).
- Never print/commit a secret VALUE (the in-process `op read` → `op item create` pattern is fine).
