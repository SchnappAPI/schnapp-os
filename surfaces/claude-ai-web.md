# Surface: claude.ai (web + chat)

- **Skills:** added in claude.ai settings (per account; org-provisioned on Team/Enterprise).
  The same SKILL.md files from this repo are used; they do not auto-sync, so enable them here.
- **Tools/credentials:** hosted MCP connectors only, enabled in Settings > Connectors. One
  **Schnapp Portal** connector is the Cloudflare MCP portal `https://mcp.schnapp.bet/mcp` (Managed
  OAuth → origins); it fronts the four static-bearer servers - **op-mcp** (secrets), **memory-mcp**,
  **mac-mcp** (shell/SQL/files), **github-mcp**: so one OAuth connector exposes all their tools.
  **obsidian-mcp** is also static-bearer now (swapped from native OAuth 2026-07-18) and joins the
  portal-fronted set once the owner adds its portal slot (pending owner step). Connector/auth
  topology + health: [`credentials-map.md`](../credentials-map.md) (which points at the vault
  `credentials-state` fact, canonical). No
  local filesystem, shell, or hooks. To USE a secret, call the Mac's `op_run`/`op_inject` (value
  scrubbed); use op-mcp `op_read` only when the Mac is off AND the portal is healthy (returns the raw
  value into chat).
- **"Must happen" behavior:** no hooks here - run the [`session-hygiene`](../skills/session-hygiene/SKILL.md)
  skill (freshness gate at start, end-of-session write when wrapping up, on-correction update after a
  correction) plus always-loaded instructions. Persist writes via the GitHub connector or a generated Code prompt.
- **Fallback:** for filesystem/shell/git actions, call the Mac via remote MCP, or generate a
  ready-to-run prompt/command for a Code session.

## Enablement (apply once 10.1 is installed)
1. **Connectors** (Settings > Connectors), confirm enabled: **Schnapp Portal**
   (`https://mcp.schnapp.bet/mcp` - fronts op-mcp + memory-mcp + mac-mcp + github-mcp; the
   obsidian-mcp slot is a pending owner add since the 2026-07-18 bearer swap - the old native-OAuth
   "obsidian mcp" standalone connector no longer authenticates). The old standalone "Schnapp Mac" /
   "Schnapp GitHub" connectors are retired - the portal carries those tools now.
2. **Skills:** do NOT paste static skill copies (a pasted `SKILL.md` goes stale, the same trap the
   CORE live-read clause avoids). With the Portal connector on (default), claude.ai reads skills
   LIVE from `skills/<name>/SKILL.md` on demand, so the substance stays current with zero
   registration. [`claude-ai-skills.md`](claude-ai-skills.md) (from
   [`scripts/gen-claude-ai-skills.sh`](../scripts/gen-claude-ai-skills.sh)) is the generated
   inventory of what is available to read live. Optional: for a skill you want the platform to
   auto-surface by description without naming it, register a THIN stub in Settings > Capabilities:
   its frontmatter (name + description) for triggering plus a one-line body that says to read the
   live `SKILL.md` and follow it. The stub is a pointer, not a copy, so it does not go stale.
3. **Always-loaded instructions:** paste the **CORE** section of
   [`always-loaded-instructions.md`](always-loaded-instructions.md) into **Settings > Profile >
   Preferences** (account-wide / global - owner's choice 2026-06-16, so it applies to every chat
   and to iPhone on the same account). CORE is a **bootstrap**: with the Schnapp Portal connector
   (on by default here, probe-confirmed 2026-07-07 in bare chats and Projects) the surface reads
   `rules/global/` live and treats it as authoritative; the pasted bullets are the floor it falls
   back to if the connector is ever down, carrying the standing rules (no sycophancy, terse, no
   capitulation, read-for-intent) that a hook delivers on Code but nothing delivers here. Use a
   dedicated Project's instructions instead only if you later want it scoped to schnapp-os work.
4. **Verify:** run `surface-check`. Expect connectors present, global rules + session-hygiene loaded,
   no hooks (expected here), persist via GitHub connector or a generated Code prompt.
