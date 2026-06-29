---
name: mac-cloud-access
metadata:
  node_type: memory
  scope: global
  source: "session 2026-06-29 (network-policy allowlist fix; corrects handoff 037 open #1)"
  updated: 2026-06-29
  supersedes: ""
---

Reaching the Schnapp Mac from Claude Code on the web / any cloud surface.

- The Mac MCP (`mac-mcp.schnapp.bet/mcp`, server `connectors/mac-mcp/server.py`) is wired as a
  **project-scoped** server in `.mcp.json` (`Schnapp_Mac`), auto-loaded from the repo — it does NOT
  depend on a claude.ai UI connector. Removing the UI "Schnapp Mac" connector does NOT cut cloud-agent
  access; `.mcp.json` is the source of truth. Auth = `Authorization: Bearer ${MAC_MCP_AUTH_TOKEN}` (env
  var, expanded at connect; the server's `_BearerAuthMiddleware` then authorizes ALL tools, no per-call token).
- **The operative gate for a web/cloud session is the environment NETWORK-POLICY allowlist.** If
  `mac-mcp.schnapp.bet` is not on the allowed-domains list, the agent proxy returns **403 on CONNECT**
  and `Schnapp_Mac` never connects (its tools are simply absent). In-session symptom: the proxy status
  (`curl "$HTTPS_PROXY/__agentproxy/status"`) shows `recentRelayFailures` with
  `connect_rejected … 403 to CONNECT` for `mac-mcp.schnapp.bet:443`. Fix = owner adds the host to the
  environment's allowed domains (web UI). Verified 2026-06-29: 403→reachable; `mac_info`/`site_health` live.
- This **corrects handoff 037 open #1**, which wrongly theorized a "duplicate UI connector shadowing
  `.mcp.json`". The real blocker was the network allowlist, not connector shadowing.
- Cold start: the host sleeps when idle; the first call after idle can take ~50s or throw one transient
  timeout — retry once before treating it as down. See [[mac-connector-tooling]] for tool semantics;
  `decisions/0014` for the access decision.
