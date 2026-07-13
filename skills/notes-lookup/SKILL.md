---
name: notes-lookup
claude-ai-tier: core
description: Use when the answer likely lives in the owner's OWN notes/knowledge - a past decision, project context, a runbook, a domain fact, or anything captured in the Obsidian vault (which mirrors schnapp-os's memory/handoffs/decisions). Search the owner's knowledge before answering from memory or rebuilding context. For EXTERNAL library/framework/API docs use context7 instead.
---

# notes-lookup

Look up the owner's own knowledge in the **Obsidian vault** before answering from training
memory or re-deriving context. The vault holds the owner's notes plus the mirrored
`claude-archive` (schnapp-os's `handoffs/`, `decisions/`, PLAN/PROGRESS - written
by `backup-archive.sh`), so past decisions and project context are searchable here.

This is for the owner's OWN knowledge. For external library/framework/API docs, use the
**context7** MCP instead - different source, different tool.

## Where to search (by surface)

| Surface | How to read the vault |
|---|---|
| **Code on the Mac** | The filesystem `obsidian` (npm) MCP: `mcp__obsidian__search-vault`, `mcp__obsidian__read-note`, `mcp__obsidian__list-available-vaults`. Or read the vault files directly at `~/Documents/Obsidian` (a symlink to the canonical `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian`). |
| **Off-Mac** (claude.ai, iPhone, Cowork) | The hosted **obsidian** connector at `https://obsidian-mcp.schnapp.bet/mcp` (Mac-hosted FastMCP; full service detail in `schnapp-bet` → `docs/CONNECTIONS.md` → "Obsidian MCP"). Read with `search_notes`, `read_note`, `list_notes` (write tools `write_note`/`append_note`/`inbox_drop` also exist - read-only suffices for lookup). **Mac-dependency caveat:** this connector is hosted on the Mac, so if the Mac is off it is unavailable - fall back to the GitHub copy / this repo's `memory/` + `decisions/`. |

Probe before relying on it (see [`verify-before-asserting`](../../rules/global/verify-before-asserting.md)):
if the obsidian tools are not present (or the Mac is off), say so and fall back to the GitHub copy
(`SchnappAPI/schnapp-vault` for memory, or schnapp-os's own `decisions/` in this repo).

## Workflow

1. **Search** by content/filename for the topic (`search-vault` on the Mac / `search_notes` off-Mac).
   Prefer specific terms (a decision name, a table, a project, an error string).
2. **Read** the most relevant note(s) (`read-note` on the Mac / `read_note` off-Mac) - do not answer
   from the search snippet alone.
3. **Answer** from what the vault actually says; quote the note/path. If the vault has nothing,
   say so plainly rather than guessing (the fact may not be captured yet).
4. If you discover the fact was missing and is durable, capture it per
   [`knowledge-capture`](../../rules/global/knowledge-capture.md) (memory lane / a vault note) so
   the next lookup finds it.

## Notes

- The vault is read-mostly here: search/read to answer. Writing durable knowledge goes through
  the memory lane (`docs/memory-lane.md`; the global lane is the vault) or a deliberate vault note,
  not ad-hoc scattering.
- Decisions live in `decisions/` (this repo) and mirror into the vault - for "why did we
  choose X", search both.
- The live server's canonical **source** is in this repo at `connectors/obsidian-mcp/server.py`
  (the Mac runs it via symlink; decisions/0008). The former Render/TS implementation was retired.
