# Handoff 002 — Part 4.2 off-Mac 1Password connector (build plan)

Date: 2026-06-03

## Where we are
- Parts 0, 1, 2, 3 done and pushed. SA rotated; `op`/`gh` work (incl. in-session).
- Runtime triaged 19 -> 6 plugins (decisions/0003). schnapp-kit frozen (tag record-2026-06-03).
- Connector design verified and recorded (decisions/0004).
- Token-for-all-repos: owner chose "user account, script per repo." Run once to cover current
  repos:
  `read -rs T; for r in $(gh repo list SchnappAPI --limit 200 --json nameWithOwner -q '.[].nameWithOwner'); do printf '%s' "$T" | gh secret set OP_SERVICE_ACCOUNT_TOKEN --repo "$r"; done; unset T`

## The build (Part 4.2)
Goal: a hosted remote MCP that resolves 1Password secrets for claude.ai/iPhone without the Mac.

1. Scaffold a Node MCP server that uses `@1password/sdk` with the Service Account token to
   read `op://` items. Tools: `op_read`, `op_list` (mirror the Mac connector's surface).
2. Host fork (decisions/0004): try **Cloudflare Worker + nodejs_compat** first; verify the
   1Password SDK actually runs (it is documented Node-only). If it fails, fall back to a
   **Node host** (Cloudflare Container / Fly / Render).
3. Auth the endpoint (workers-oauth-provider or Cloudflare Access / bearer). SA token is a
   host secret, never in the repo.
4. Register the HTTPS URL in claude.ai (Settings > Connectors > Add custom connector), and on
   Code/Cowork.
5. Verify (PLAN.md check 7): resolve a secret from claude.ai with the Mac off.

## Next session prompt
"Resume claude-kit PLAN.md, Part 4.2. Read decisions/0004 and this handoff. Scaffold the Node
1Password MCP connector under connectors/op-mcp/, verify the SDK runs under Worker
nodejs_compat, else use a Node host. Then wire auth and register in claude.ai."
