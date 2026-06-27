# 0014 — Enable autonomous cloud-agent Mac access (refines 0013)

Date: 2026-06-27. Status: DECIDED by owner (deliberate re-decision, same day as 0013).

## Context
ADR 0013 set "no standing shell access" for cloud agents — privileged Mac tools (`shell_exec`,
`op_run`, `read_file`, `write_file`, `sql_query`) gated behind per-call authorization, with read-only
introspection allowed. In practice this meant the agentic-OS experience ("ask → the agent does it →
returns a verified result") held for the git/GitHub domain but NOT for the production Mac: every Mac
action required the owner to relay through a terminal. The owner explicitly rejected that as not the
OS they want.

The `mac-mcp` server already supports transport-level auth: `_BearerAuthMiddleware` authorizes a
request carrying `Authorization: Bearer <MAC_MCP_AUTH_TOKEN>`, after which `_check_token()` passes for
every tool with no per-call token argument. This is the same mechanism the claude.ai connector already
uses. The cloud Code connector simply was not sending that header.

## Decision
Enable the `Authorization: Bearer ${MAC_MCP_AUTH_TOKEN}` header on the cloud Code `Schnapp_Mac`
connector, granting this surface full Mac tool access (incl. `shell_exec`/`op_run`). This **refines
0013**: cloud-agent Mac access is now permitted, by deliberate owner choice, so the loops and ops can
be driven end-to-end without manual relay.

## Why the owner accepts the blast radius
- **The token never enters the transcript.** It lives only in the connector config (ideally as an
  `${MAC_MCP_AUTH_TOKEN}` reference), resolved at the transport layer — not materialized to the model.
- **Secrets stay protected even with shell.** `shell_exec` runs with the 1Password identity stripped
  AND a poisoned SA token (`_no_op_identity_env`), so a general shell cannot read vault secrets; secret
  access is only via `op_run`, which injects values into the child and scrubs them from output.
  `service_status`/`launchctl print` output is secret-redacted (`_redact_secrets`).
- **Single-owner production host.** The owner is the only principal; "an agent turn could run shell"
  is, here, "the owner's agent could run shell on the owner's machine."
- **`sql_query` is read-only** (write keywords blocked); destructive DB ops still require explicit shell.

## Consequences
- The agent can now seed captures, run the learning worker, inspect logs, and verify Mac state
  autonomously — closing the last manual-relay gap in the loops.
- If the connector config (and thus the bearer) is ever exposed, rotate `MAC_MCP_AUTH_TOKEN`
  (self-serve `openssl`; handoff 032/033 procedure) and reconnect.
- If this ever becomes multi-user or the host gains higher-risk surface, revisit and move to the
  scoped-tool model (narrow `enqueue_capture`/`run_learning_worker` instead of general shell) that
  0013 pointed at.
- 0013 still stands as the rationale record; this ADR is the owner's deliberate exception to it.
