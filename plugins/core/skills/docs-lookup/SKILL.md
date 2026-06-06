---
name: docs-lookup
description: Use when the answer likely lives in the owner's OWN notes/knowledge — a past decision, project context, a runbook, a domain fact, or anything captured in the Obsidian vault (which mirrors claude-kit's memory/handoffs/decisions). Search the owner's knowledge before answering from memory or rebuilding context. For EXTERNAL library/framework/API docs use context7 instead.
---

# docs-lookup

Look up the owner's own knowledge in the **Obsidian vault** before answering from training
memory or re-deriving context. The vault holds the owner's notes plus the mirrored
`claude-archive` (claude-kit's `memory/`, `handoffs/`, `decisions/`, PLAN/PROGRESS — written
by `backup-archive.sh`), so past decisions and project context are searchable here.

This is for the owner's OWN knowledge. For external library/framework/API docs, use the
**context7** MCP instead — different source, different tool.

## Where to search (by surface)

| Surface | How to read the vault |
|---|---|
| **Code on the Mac** | The filesystem `obsidian` MCP: `mcp__obsidian__search-vault`, `mcp__obsidian__read-note`, `mcp__obsidian__list-available-vaults`. Or read `~/Documents/Obsidian` files directly. |
| **Off-Mac** (claude.ai, iPhone, Cowork) | The remote **obsidian-mcp** connector ([`connectors/obsidian-mcp`](../../../../connectors/obsidian-mcp/)): `vault_search`, `vault_read`, `vault_list`, `vault_health`. Serves the vault from GitHub — no Mac/app dependency. |

Probe before relying on it (see [`verify-before-asserting`](../../rules/global/verify-before-asserting.md)):
if neither tool is present on this surface, say so and fall back to the GitHub copy
(`SchnappAPI/obsidian-vault`, or claude-kit's own `memory/`/`decisions/` in this repo).

## Workflow

1. **Search** by content/filename for the topic (`search-vault` / `vault_search`). Prefer
   specific terms (a decision name, a table, a project, an error string).
2. **Read** the most relevant note(s) (`read-note` / `vault_read`) — do not answer from the
   search snippet alone.
3. **Answer** from what the vault actually says; quote the note/path. If the vault has nothing,
   say so plainly rather than guessing (the fact may not be captured yet).
4. If you discover the fact was missing and is durable, capture it per
   [`knowledge-capture`](../../rules/global/knowledge-capture.md) (memory lane / a vault note) so
   the next lookup finds it.

## Notes

- The vault is read-mostly here: search/read to answer. Writing durable knowledge goes through
  the memory lane (`memory/README.md`) or a deliberate vault note, not ad-hoc scattering.
- Decisions live in `decisions/` (this repo) and mirror into the vault — for "why did we
  choose X", search both.
