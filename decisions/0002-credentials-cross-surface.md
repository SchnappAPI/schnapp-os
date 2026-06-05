# 0002 — Cross-surface credentials: open items (2026-06-03)

## All-repos GitHub Actions token
- GitHub **user** accounts (SchnappAPI is one) have NO "all repositories incl. future"
  Actions secret. Only **Organizations** offer an org secret with visibility = All
  repositories (covers current + future automatically).
- Options:
  - (A) Use a GitHub Organization for true auto-coverage of future repos.
  - (B) Stay on the user account: set per repo. Script sets all current repos:
    `for r in $(gh repo list SchnappAPI --limit 200 --json nameWithOwner -q '.[].nameWithOwner'); do gh secret set OP_SERVICE_ACCOUNT_TOKEN --repo "$r"; done`
    Future repos handled by `/new-project` adding the secret at creation.
- DECISION (RESOLVED 2026-06-03): owner chose **(B)** user account + per-repo script. PAT later
  widened to all repos; the secret is set on the authorized repos (incl. `af-invoice-parser`,
  `af-query-api`). `DB_Storage` + `appfolio-marketing-project` left unset pending owner (never scoped).

## 1Password access on every surface without the Mac
- The SA token works on ANY machine running `op` (Code on work laptop/desktop: put the token
  in that machine's env; no Mac needed).
- Gap: claude.ai and iPhone have no shell and currently reach 1Password only via the Mac MCP.
- Fix (Part 4.2): host the 1Password MCP server OFF the Mac (Cloudflare Worker/container),
  service-account-backed, add as a connector on claude.ai. Official 1Password + Anthropic
  "Unified Access" integration is also rolling out (Mar 2026) for browser ext / Cowork / Code.
- DECISION (RESOLVED 2026-06-05): BUILT the self-hosted connector — Node host on **Render**
  (`https://op-mcp.onrender.com`), fronted by a **Cloudflare MCP portal** (`https://mcp.schnapp.bet/mcp`,
  Managed OAuth). LIVE + verified from claude.ai. The Cloudflare *Worker* path was ruled out (the
  1Password SDK needs Node; decisions/0004). No general official 1Password remote MCP exists (only
  the May-2026 OpenAI-Codex one), so self-host stays. Full record: decisions/0004 + connectors/op-mcp/DEPLOY.md.

Supersedes the earlier assumption that SA rotation alone completed Part 4.
