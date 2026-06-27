# 0013 — Cloud agents do not get standing shell access to the production Mac

Date: 2026-06-27. Status: DECIDED by owner (during the Phase 4 learning-worker activation).

## Context
Finishing the learning loop required operating the production Mac (install/load the LaunchAgent, test
the credential, run the worker). The cloud session reaches the Mac through the `Schnapp_Mac` MCP
connector (`mac-mcp.schnapp.bet` → `com.schnapp.macmcp`), authenticated with a transport bearer
(`op://web-variables/MAC_MCP_AUTH_TOKEN/credential`). Read-only introspection tools (`service_status`,
`mac_info`, vault listing) work with no extra step. The **privileged** tools — `shell_exec`, `op_run`,
`read_file`, `write_file`, `sql_query` — additionally require the `MAC_MCP_AUTH_TOKEN` value as a
per-call argument.

During activation the auto-accept classifier **denied** materializing `MAC_MCP_AUTH_TOKEN` into the
session transcript, so the agent could not self-drive the Mac's shell. The question raised: should we
remove that friction (e.g. put the token in an agent-readable env) so the agent can run Mac shell
commands directly?

## Decision
**No standing shell access.** Cloud agent sessions get read-only Mac introspection by default;
arbitrary `shell_exec`/`op_run` on the production Mac stays gated behind explicit, per-action
authorization. We will NOT drop the raw `MAC_MCP_AUTH_TOKEN` into an agent-readable `.env` or the
environment's variables to make privileged Mac calls frictionless.

Rationale:
- **Blast radius.** A standing shell token in the session env grants *any* agent turn arbitrary code
  execution + `op_run` (secret-injected commands) on the machine that hosts production (SQL Server,
  the live site, the runner, backups). The per-call friction is a safety boundary, not a bug.
- **Secrets-as-references (0011 #4 / rules/global/secrets-as-references).** A shell token sitting in a
  readable env is a resolved secret at rest; it contradicts the lane's own principle.
- The friction cost is bounded: the owner runs the rare privileged step, or approves it once.

## If autonomous Mac ops are ever wanted (the sanctioned path)
Do it deliberately, not by leaking a token:
- Configure the **connector** to inject the privileged bearer at the transport layer (as it already
  does for the read-only tools), so the value never enters a transcript; and
- **Scope** what the agent may do (allow-list specific commands/operations), rather than granting a
  general shell.
Record that as its own decision when taken.

## Consequences
- The learning-worker is activated/maintained on the Mac by the owner (or an explicitly-approved
  step), not by an autonomous cloud turn. This matches Phase 4's "activation is owner-confirmed,
  production-Mac-only" policy (`scheduled-tasks/README.md`).
- `MAC_MCP_AUTH_TOKEN` was NOT exposed this session — the classifier denied the read before any value
  entered the transcript, which is exactly the boundary working. (If it ever does transit, treat it as
  exposed and rotate per handoff 033.)
- This refines, not supersedes, 0011 #5 (centralized remote-MCP credential delivery): reading secrets
  is fine via the connector; what is gated is privileged *execution* on the production host.
