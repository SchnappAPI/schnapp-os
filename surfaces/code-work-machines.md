# Surface: Claude Code on work laptop / work desktop (restricted)

Claude Code runs here, but the machines have work restrictions. STUB: verify specifics per
machine and fill in.

- **Credentials:** needs `OP_SERVICE_ACCOUNT_TOKEN` in that machine's shell env (same rotate
  step as the Mac). Verify `op whoami` works.
- **Git:** SSH key must be present and authorized; verify `ssh -T git@github.com`.
- **Tools:** GitHub MCP + hosted connectors work. Local Mac tools are NOT here; reach the Mac
  via its remote MCP when needed.
- **Hooks:** run here (Claude Code), same as the Mac — after this machine's workspace-trust dialog
  is accepted. Delivered plugin-wide at Part 10 ([decisions/0005](../decisions/0005-hook-delivery-split.md)).
- **To verify and record:** which connectors are enabled, whether `op`/`gh` are installed,
  any network/proxy limits.
