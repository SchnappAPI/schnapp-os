# Handoff 061: cross-repo cohesion audit (all ~/code repos vs schnapp-os canon)

Date: 2026-07-18. Surface: Code (Mac). Prior: [060](060-cross-surface-close-substrate-p2-p3.md).

## Goal
Owner: "my repos all communicate and are cohesive and not competing with each other; schnapp-os
holds the keys that affect everything." Audit every repo under `~/code` for restated global rules,
contradictions with the global lane, duplicated tooling, and stale references to retired
schnapp-os components (github-mcp ADR 0036, obsidian-mcp auth ADR 0035, `.claude/skills` ban
handoff 058). Fix clear duplication/stale; KEEP-flag deliberate project-lane rules.

## Facts established
- `web-bad` is NOT a separate repo: its origin is `SchnappAPI/schnapp-bet.git`. It was a second
  local clone, 192 commits behind; its "divergences" (stale obsidian OAuth doc, wrong repo path)
  were just clone lag. Fast-forwarded to main; now identical.
- The hardcoded AppFolio pair in `appfolio-marketing-project/MarketingProject/param.pq` byte-matched
  the LIVE `op://web-variables/APPFOLIO_API` client_id/client_secret. New open exposure, not part
  of the owner-accepted 2026-06-17 set. Scrubbed working tree; rotation pending (ledger entry).
- schnapp-bet/web-bad `claude.yml` responder installed the retired schnapp-kit as a plugin
  marketplace in every CI @claude session (removed). Only schnapp-bet had this; sports-modeling
  and the appfolio fleet do not.
- github-mcp teardown state: tunnel ingress already removed by owner (handoff 060 era); DNS CNAME
  still resolves (Cloudflare 404 catch-all answers). `~/github-mcp` runtime dir removal + DNS
  record deletion remain the ADR 0036 owner legs.
- appfolio fleet (af-invoice-parser, af-query-api, appfolio-mcp, appfolio-quickbase-sync,
  appfolio-fish-pipeline-reference), schnapp-qb, chat-archive, DB_Storage, ref-vault: no local
  rules/hooks/gates that compete with the global lane. Cohesive-by-absence.

## Decisions + reasoning
- KEEP (deliberate project lane): schnapp-bet's `.githooks/commit-msg` subject format + post-commit
  auto-push + destructive/ADR-protect hooks (its own ADR-20260517-3/4, ADR-20260524-1; subject
  regex does not conflict with the Co-Authored-By trailer, which lives in the body). KEEP the
  vault's flattener hook (ADR 0029) and vendored secret-scan (server-side backstop with drift
  guard). KEEP appfolio-fish-pipeline-reference's `.env.example` restatement (standalone reference
  repo, no op wiring).
- FIX (competition/stale): schnapp-kit froze but still advertised itself installable and wired
  active project hooks (its own CLAUDE.md claimed they were inert; `.claude/settings.json` proved
  otherwise). Banner + disarm, not delete: renamed `.claude/settings.json` ->
  `settings.frozen.json`, unset `core.hooksPath` on the clone; record stays intact.
- claude-skills (rsync-copies into `~/.claude/skills/`) contradicts the symlink distribution
  (ADR 0033, handoff 058): superseded banner + GitHub repo archived (reversible).
- Em dashes in touched instruction files swept to the global writing style (the machine-wide
  em-dash-on-write hook enforces on every write, so any future edit pays this anyway).

## Actions + outcomes
All pushed green:
- schnapp-bet `1174d15`, `cc0b2cf`, +teardown-state correction: CLAUDE.md GitHub-MCP section ->
  official server via portal (`get_file_contents`), CONNECTIONS.md github section + Cloudflare row
  rewritten, launchd README githubmcp bullet dropped, claude.yml kit-install step removed
  (workflow push needed the op GITHUB_PAT; the default OAuth cred lacks `workflow` scope).
- web-bad clone: ff-only to main (all fixes inherited).
- sports-modeling: CONNECTIONS row + GitHub-MCP bullet (no scope lock now), SESSION_PROTOCOL
  `get_file` -> `get_file_contents`, CHANGELOG entry per its own protocol.
- schnapp-console: `server.py` GitHub live-read probe repointed `github-mcp.schnapp.bet` ->
  `https://api.githubcopilot.com/mcp/` (old probe hit Cloudflare 404 = counted UP: false-healthy
  consistency signal); gitignored local `deploy-config.yml` ingress entry dropped; agent
  restarted, serving 200.
- schnapp-vault: `memory/obsidian-state.md` OAuth claim superseded (ADR 0035);
  `credentials-state.md` bearer set updated (GITHUB_MCP_AUTH_TOKEN deleted, OBSIDIAN_MCP_AUTH_TOKEN
  added) + OPEN APPFOLIO_API exposure logged; MEMORY.md index synced; brain-capture skill
  repointed obsidian-vault/`~/Documents/Obsidian` -> `~/code/schnapp-vault`.
- schnapp-kit: frozen banners (README/CLAUDE/ROADMAP), hooks disarmed.
- claude-skills: superseded banner, repo archived.
- Loose `~/code/_refmap_scan.py` + `_refmap_render.py` (pre-schnapp-os plugin-era analysis,
  duplicated gen-catalog/diagnostics): moved to `~/.Trash`.

## Status + next steps
Audit complete; every repo verdict recorded (table in the session reply). Owner legs below are the
only remaining work. Task chips filed: ref-vault consolidation (handoff 029 target), web-bad
second-clone retirement decision.

## Open questions / edge cases
- OWNER (priority): rotate the AppFolio API key (AppFolio admin UI), update
  `op://web-variables/APPFOLIO_API` fields, re-enter in Power BI models; collapse the ledger entry.
  Git history of appfolio-marketing-project still holds the old values (private repo; moot after
  rotation).
- OWNER (ADR 0036 legs): delete the `github-mcp.schnapp.bet` DNS record (still resolves);
  `rm -rf ~/github-mcp`.
- web-bad: keep as a second clone of schnapp-bet or remove the directory? (Chip filed; removal is
  destructive so not taken unilaterally.)

## Copy-paste primer (new session)
Cross-repo cohesion audit (handoff 061) is done: all ~/code repos reconciled against schnapp-os
canon, fixes pushed per-repo, schnapp-kit/claude-skills frozen+archived, APPFOLIO_API leak scrubbed
and logged OPEN in the vault ledger pending owner rotation. Next action: confirm the AppFolio
rotation happened, then collapse the ledger entry; remaining ADR 0036 owner legs are the DNS record
and ~/github-mcp dir.
