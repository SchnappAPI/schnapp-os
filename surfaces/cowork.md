# Surface: Cowork

Desktop app on the Claude Agent SDK. Consumes plugins.

- **Skills/commands/agents:** install `schnapp-os` as a plugin. Cowork can connect a private
  GitHub repo and auto-sync its plugins, so it tracks this repo.
- **Tools/credentials:** hosted MCP connectors only — the **Schnapp Portal** (op + memory + mac +
  github) and **obsidian mcp** — or the same servers via `.mcp.json` if Cowork reads project servers.
  No local shell.
- **Hooks:** Cowork does **NOT** run schnapp-os's hooks — RESOLVED by `surface-check` on two
  Cowork sessions (Mac + HP) 2026-06-16: neither saw the SessionStart gate fire automatically; both
  fell back to manual session-hygiene. So treat Cowork as hookless: rely on the
  [`session-hygiene`](../.claude/skills/session-hygiene/SKILL.md) skill + always-loaded
  instructions for "must happen" behavior, and persist via the GitHub connector. The plugin's
  [`hooks/hooks.json`](../hooks/hooks.json) is inert here; the SessionEnd backup never
  fires from Cowork regardless (project-scoped, decision 0005).
- **Fallback:** for anything Cowork cannot do natively, call the Mac via remote MCP, or
  generate a prompt for a Code session.

## Enablement (apply once 10.1 is installed)
1. **Connect the repo + plugin:** in Cowork, add `SchnappAPI/schnapp-os` and install the
   `schnapp-os-core` plugin (Cowork consumes plugins and auto-syncs the repo). This delivers the
   skills, commands, and agents (and the gate + push-gate hooks IF Cowork runs hooks).
2. **Connectors:** enable the **Schnapp Portal** (op + memory + mac + github) + **obsidian mcp**
   (hosted MCP only; no local shell). The old "1Password / Schnapp Mac / Schnapp GitHub" connectors
   are retired (folded into the portal).
3. **Hooks:** confirmed Cowork does NOT run them (surface-check, 2026-06-16) — rely on
   `session-hygiene` + the always-loaded block; persist via the GitHub connector. The SessionEnd
   backup stays schnapp-os-project-scoped either way (decision 0005), so it never fires from Cowork.
4. **Always-loaded instructions:** add [`always-loaded-instructions.md`](always-loaded-instructions.md)
   as Cowork instructions.
5. **Verify:** run `surface-check`.
