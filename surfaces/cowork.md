# Surface: Cowork

Desktop app on the Claude Agent SDK. Hookless and shell-less; state rides the
[handoff packet](../docs/memory-lane.md#handoff-packet-cross-surface-resume) through the two
git repos (`SchnappAPI/schnapp-os` + `SchnappAPI/schnapp-vault`) via the GitHub connector
(decisions/0027).

- **Instructions/skills:** the plugin path is gone (the Phase-2 flatten deleted the
  marketplace + plugin, [decisions/0024](../decisions/0024-flatten-plugin-native-claude.md)).
  Behavior arrives via the always-loaded block
  ([always-loaded-instructions.md](always-loaded-instructions.md)); read any skill or rule
  file from the repo through the connector on demand.
- **Tools/credentials:** hosted MCP connectors only - the **Schnapp Portal** (op + memory +
  mac + github legs) and **obsidian-mcp**. No local shell. The github leg (github-mcp)
  authenticates GitHub with `GITHUB_PAT` (all-repos, [credentials-map](../credentials-map.md)),
  so both repos including the vault are in scope; verify per enablement 3. Whether Cowork also
  reads project `.mcp.json` servers is UNVERIFIED (probe: enablement 4).
- **Hooks:** none run here - RESOLVED by `surface-check` on two Cowork sessions (Mac + HP)
  2026-06-16. Run the must-happen procedures by hand via
  [`session-hygiene`](../skills/session-hygiene/SKILL.md); persist via the connector.
  The SessionEnd backup is Code/Mac-scoped and never fires from Cowork.
- **Fallback:** anything Cowork cannot do natively: call the Mac over its remote MCP, or
  generate a ready-to-run prompt for a Code session. Never silently skip.

## Enablement
1. **Connectors:** enable the **Schnapp Portal** (op + memory + mac + github) + **obsidian-mcp**.
2. **Always-loaded instructions:** paste the **CORE** section + the **Cowork operating block** of
   [always-loaded-instructions.md](always-loaded-instructions.md) into Cowork instructions (CORE =
   behavior; the block = agentic work rules: connector topology, session-hygiene, read-modify-write
   repo writes, main-only + auto-push).
3. **Vault access verify (streamline Phase 5 T1):** in a Cowork session, read a vault fact
   (fetch `memory/MEMORY.md` from `SchnappAPI/schnapp-vault` through the connector), then write
   one (a probe fact per the vault `agents.md` schema, plus its `MEMORY.md` index line). Both
   succeeding = the vault read/write path is live. Exact leg:
   [handoffs/049](../handoffs/049-phase-5-cowork-packet-repo-side.md).
4. **memory-mcp probe (optional upgrade, Phase 5 T3):** in the same session, check for the
   memory tools (`memory_health`, `memory_list`). Healthy = schema-validated `memory_*` writes
   become the front-line for the vault memory leg (decisions/0027 upgrade path); otherwise stay
   on connector file writes.
5. **Verify the surface:** run `surface-check`.
