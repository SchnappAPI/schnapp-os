# Surface: Cowork

Desktop app on the Claude Agent SDK. Consumes plugins.

- **Skills/commands/agents:** install `claude-kit` as a plugin. Cowork can connect a private
  GitHub repo and auto-sync its plugins, so it tracks this repo.
- **Tools/credentials:** hosted MCP connectors only (1Password, GitHub, Mac ops). No local
  shell.
- **Hooks:** UNVERIFIED whether Cowork executes hooks. Treat as no until confirmed (Part 7.2);
  rely on skills + always-loaded instructions for "must happen" behavior here.
- **Fallback:** for anything Cowork cannot do natively, call the Mac via remote MCP, or
  generate a prompt for a Code session.
