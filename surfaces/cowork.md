# Surface: Cowork

Desktop app on the Claude Agent SDK. Consumes plugins.

- **Skills/commands/agents:** install `claude-kit` as a plugin. Cowork can connect a private
  GitHub repo and auto-sync its plugins, so it tracks this repo.
- **Tools/credentials:** hosted MCP connectors only (1Password, GitHub, Mac ops). No local
  shell.
- **Hooks:** UNVERIFIED whether Cowork executes hooks. Treat as no until confirmed (Part 7.2);
  rely on the [`session-hygiene`](../plugins/core/skills/session-hygiene/SKILL.md) skill +
  always-loaded instructions for "must happen" behavior here. If Cowork IS later confirmed to run
  hooks, the plugin's [`hooks/hooks.json`](../plugins/core/hooks/hooks.json) covers it and the skill
  becomes the manual fallback.
- **Fallback:** for anything Cowork cannot do natively, call the Mac via remote MCP, or
  generate a prompt for a Code session.

## Enablement (apply once 10.1 is installed)
1. **Connect the repo + plugin:** in Cowork, add `SchnappAPI/claude-kit` and install the
   `claude-kit-core` plugin (Cowork consumes plugins and auto-syncs the repo). This delivers the
   skills, commands, and agents (and the gate + push-gate hooks IF Cowork runs hooks).
2. **Connectors:** enable 1Password, Schnapp Mac, GitHub (hosted MCP only; no local shell).
3. **Hooks:** still UNVERIFIED whether Cowork runs them. Until confirmed, rely on `session-hygiene`
   + the always-loaded block. If confirmed, the plugin's `hooks.json` owns gate + push-gate and the
   skill is the manual fallback. The SessionEnd backup stays claude-kit-project-scoped either way
   (decision 0005), so it never fires from Cowork sessions in other repos.
4. **Always-loaded instructions:** add [`always-loaded-instructions.md`](always-loaded-instructions.md)
   as Cowork instructions.
5. **Verify:** run `surface-check`.
