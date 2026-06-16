# Surface: Cowork

Desktop app on the Claude Agent SDK. Consumes plugins.

- **Skills/commands/agents:** install `claude-kit` as a plugin. Cowork can connect a private
  GitHub repo and auto-sync its plugins, so it tracks this repo.
- **Tools/credentials:** hosted MCP connectors only (1Password, GitHub, Mac ops). No local
  shell.
- **Hooks:** Cowork does **NOT** run claude-kit's hooks — RESOLVED by `surface-check` on two
  Cowork sessions (Mac + HP) 2026-06-16: neither saw the SessionStart gate fire automatically; both
  fell back to manual session-hygiene. So treat Cowork as hookless: rely on the
  [`session-hygiene`](../plugins/core/skills/session-hygiene/SKILL.md) skill + always-loaded
  instructions for "must happen" behavior, and persist via the GitHub connector. The plugin's
  [`hooks/hooks.json`](../plugins/core/hooks/hooks.json) is inert here; the SessionEnd backup never
  fires from Cowork regardless (project-scoped, decision 0005).
- **Fallback:** for anything Cowork cannot do natively, call the Mac via remote MCP, or
  generate a prompt for a Code session.

## Enablement (apply once 10.1 is installed)
1. **Connect the repo + plugin:** in Cowork, add `SchnappAPI/claude-kit` and install the
   `claude-kit-core` plugin (Cowork consumes plugins and auto-syncs the repo). This delivers the
   skills, commands, and agents (and the gate + push-gate hooks IF Cowork runs hooks).
2. **Connectors:** enable 1Password, Schnapp Mac, GitHub (hosted MCP only; no local shell).
3. **Hooks:** confirmed Cowork does NOT run them (surface-check, 2026-06-16) — rely on
   `session-hygiene` + the always-loaded block; persist via the GitHub connector. The SessionEnd
   backup stays claude-kit-project-scoped either way (decision 0005), so it never fires from Cowork.
4. **Always-loaded instructions:** add [`always-loaded-instructions.md`](always-loaded-instructions.md)
   as Cowork instructions.
5. **Verify:** run `surface-check`.
