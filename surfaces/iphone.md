# Surface: Claude iPhone app

Most limited. Use for capture, quick questions, and triggering remote work.

- **Tools/credentials:** hosted MCP connectors only. No local anything. The **1Password**
  connector (op-mcp portal, same as claude.ai web) resolves `op://` secrets here off-Mac; to
  *use* a secret prefer the Mac's `op_run`/`op_inject` via the Mac connector when it is on.
- **Skills:** whatever is enabled on the account.
- **Best use:** dictate context, fire a routine on the Mac via remote MCP, review status.
- **Fallback:** anything it cannot do natively is routed to the Mac via remote MCP, or
  returned as a prompt to run later on Code.
