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
- DECISION: pending owner (A vs B).

## 1Password access on every surface without the Mac
- The SA token works on ANY machine running `op` (Code on work laptop/desktop: put the token
  in that machine's env; no Mac needed).
- Gap: claude.ai and iPhone have no shell and currently reach 1Password only via the Mac MCP.
- Fix (Part 4.2): host the 1Password MCP server OFF the Mac (Cloudflare Worker/container),
  service-account-backed, add as a connector on claude.ai. Official 1Password + Anthropic
  "Unified Access" integration is also rolling out (Mar 2026) for browser ext / Cowork / Code.
- DECISION: pending owner (build Cloudflare-hosted connector vs wait for official integration).

Supersedes the earlier assumption that SA rotation alone completed Part 4.
