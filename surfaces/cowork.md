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
