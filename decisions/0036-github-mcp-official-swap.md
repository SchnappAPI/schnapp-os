# 0036 — github-mcp slot re-origined to GitHub's official MCP server; hand-rolled connector decommissioned

Date: 2026-07-18. Status: DECIDED and EXECUTED (substrate P2).

## Context
The 2026-06-30 substrate rethink (docs/repo-review-2026-06-30-substrate-rethink.md) greenlit
replacing the hand-rolled github-mcp connector (756 LOC Python, launchd `com.schnapp.githubmcp`,
port 8766, cloudflared host `github-mcp.schnapp.bet`, static bearer `GITHUB_MCP_AUTH_TOKEN`) with
GitHub's official MCP server. A 2026-07-18 re-verification confirmed the case, with one finding
that changed the expected payoff: the official server needs an `X-MCP-Toolsets` header to expose
the full toolsets, and the Cloudflare portal CAN set custom headers per server entry - so the swap
keeps the single-portal topology (no extra connector hop dropped, but none added either; the
drops-the-portal-hop payoff died, the kill-756-LOC-and-a-Mac-service payoff stood).

## Decision
The portal's github-mcp slot is re-origined to `https://api.githubcopilot.com/mcp/` with two
portal-side headers: `Authorization: Bearer <op://web-variables/GITHUB_PAT/token>` and
`X-MCP-Toolsets: context,repos,issues,pull_requests,actions,orgs`. The Mac service, tunnel host,
756-LOC server, and `GITHUB_MCP_AUTH_TOKEN` bearer (1Password item, `.env.template` line,
credentials-map row) are deleted. Tool names are now the official ones (`get_file_contents`,
`issue_read`/`issue_write`, `pull_request_read`, `actions_list`, `get_job_logs`,
`create_or_update_file`, `push_files`, ...). Four hand-rolled tools have no direct official
equivalent; accepted with workarounds: `get_repo`/`get_branch` via list+filter, `compare_commits`
via `list_commits`, `create_release` via `gh` CLI on a Code surface.

## Verification (2026-07-18, live through claude.ai)
46 official tools listed through the portal slot; read probe (`SchnappAPI/schnapp-vault`
PROGRESS.md via `get_file_contents`) OK; write/delete round trip on the vault repo OK (create
commit `36a471c`, delete commit `8bfdb88`). Teardown verified on the Mac: `launchctl bootout`
clean, label absent from `launchctl list`, nothing LISTENing on 8766, plist renamed
`retired-com.schnapp.githubmcp.plist.bak-2026-07-18`.

## Consequences
- One fewer Mac service, tunnel host, bearer, and 756 LOC to operate and rotate; the github leg
  is now Mac-independent (survives the Mac being off, like the Render pair).
- `GITHUB_PAT` rotation gains a portal leg: update the github-mcp slot's Authorization header in
  the Cloudflare console.
- Rollback: re-add a custom-header portal server entry pointing at the tunnel origin, restore the
  `.bak` plist (`mv` back + `launchctl bootstrap`), and `git revert` the connector deletion
  commit (which also restores the bearer's map row; the 1Password item would need re-minting).
- Owner legs: remove the standalone GitHub official connector from claude.ai (the portal slot
  carries it); delete the `github-mcp.schnapp.bet` tunnel ingress + DNS record; delete the
  runtime dir `~/github-mcp` (venv + logs, untracked).
