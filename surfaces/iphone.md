# Surface: Claude iPhone app

Most limited. Use for capture, quick questions, and triggering remote work.

- **Tools/credentials:** hosted MCP connectors only. No local anything. The **1Password**
  connector (op-mcp portal, same as claude.ai web) resolves `op://` secrets off-Mac when the
  hosted op-mcp is healthy (current status: [`memory/credentials-state.md`](../memory/credentials-state.md));
  to *use* a secret prefer the Mac's `op_run`/`op_inject` via the Mac connector when it is on.
- **Skills:** whatever is enabled on the account.
- **"Must happen" behavior:** no hooks — the [`session-hygiene`](../plugins/core/skills/session-hygiene/SKILL.md)
  skill applies as on claude.ai, but iPhone is for triggering: prefer firing the procedure on the Mac
  via remote MCP over doing the repo write from the phone.
- **Best use:** dictate context, fire a routine on the Mac via remote MCP, review status.
- **Fallback:** anything it cannot do natively is routed to the Mac via remote MCP, or
  returned as a prompt to run later on Code.

## Enablement (apply once 10.1 is installed)
- Same account as claude.ai web, so the connectors and the account-wide **Profile > Preferences**
  (global) instructions carry over automatically. In the iPhone app, confirm the connectors are
  toggled on; skills follow the account.
- This surface is for capture and triggering: prefer firing the procedure on the Mac via the Schnapp
  Mac connector over doing a repo write from the phone.
- **Verify:** run `surface-check` (most limited surface; hosted connectors only, no hooks).
