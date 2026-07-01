# Handoff 042 — Broad brainstorm: streamline schnapp-os (repo-flattening as one checkpoint)

**Date:** 2026-06-30. **Surface:** fresh session, owner intends **Opus 4.8** (no programmatic
model selector on `spawn_task` — pick it manually at session start).
**Not a continuation of built work** — this is a kickoff for a genuine brainstorm, not a task list.
**Resume point for:** the broader "how should schnapp-os function going forward" conversation,
using repo-flattening (decisions/0011 #2) as one concrete checkpoint inside it, not the whole scope.

---

## The ask, in the owner's own terms (carry this forward exactly)
Owner's stated direction: **"streamline everything and make it easier to understand without
sacrificing performance or capability."** Repo-flattening was one expression of that direction.
Owner wants to reconsider it against the broader direction, "but not holding strictly to it."

**How this session must run** (owner was explicit — this is not optional):
- Genuine brainstorm. Owner shares how they want things to function; agent responds.
- **Object when warranted, with real reasoning** — not reflexively, not to be contrarian.
- **Proactively surface non-obvious ideas with a real payoff** — not an exhaustive dump, genuinely
  high-value ones only.
- Not blind instruction-following. This is the explicit correction to guard against.
- The `superpowers:brainstorming` skill's mechanics fit well here (one question at a time, propose
  2-3 approaches, present design in sections, approval before implementation) — but the owner's
  framing above is the actual bar; follow it first if the two ever pull apart.

## Repo-flattening (decisions/0011 #2) — context to start from, hold loosely
Original decision (2026-06-23): *"Repo form → Plainer repo. Drop the marketplace-plugin +
`plugins/core/` packaging. This is one OS for the owner, not a distributable plugin."*

Deferred four separate times since, each for a concrete reason:
1. 06-23, same session: blocked — dropping the plugin severed the only delivery vehicle for the
   global freshness+push hooks. **Resolved same session** (hooks moved to direct paths in
   `.claude/settings.json`).
2. 06-23, later: "riskier — plugin still delivers skills/rules/commands." The real, never-resolved
   blocker.
3-4. Listed again in passing twice more, never revisited.

**Unblocked this session** (2026-06-30, verified via the `claude-code-guide` subagent, cited docs):
Claude Code natively discovers `.claude/skills/<name>/SKILL.md`, `.claude/commands/<name>.md`,
`.claude/agents/<name>.md` at the project level — **zero plugin or marketplace needed.** Sources:
`code.claude.com/docs/en/skills.md`, `sub-agents.md`, `plugins.md` ("When to use plugins vs
standalone configuration").

**Scope if executed as originally conceived** (paused here, not started):
- Move `plugins/core/{skills (24 dirs), commands (3), agents (3)}` → `.claude/{skills,commands,agents}/`.
- Move `plugins/core/{rules,scripts,hooks}` → top-level `rules/`, `scripts/`, `hooks/`.
- Delete `.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`; uninstall
  the cached `schnapp-os-core@schnapp-os` plugin locally.
- Retarget ~20 LIVE docs (CLAUDE.md, README.md, PLAN.md, memory/*, surfaces/*, templates/*, 2 CI
  workflows, `gen-catalog.sh`) + `.claude/settings.json` hook paths off the old paths.
- Update `~/.claude/CLAUDE.md`'s `@import` paths — **outside this repo, per-machine.** This Mac is
  fixable directly; any other machine the owner uses needs the same one-line edit by hand.
- ~40 historical files (`handoffs/`, `decisions/`, dated review docs) correctly reference the old
  paths and should stay untouched — they describe the past, not live state (anti-stale exemption).
- Possible bonus: `docs/repo-review-2026-06-30-substrate-rethink.md` P1 lists an open "resolve the
  `schnapp-os-core` double-load" item — dropping the plugin entirely may make it moot. Worth
  checking before doing it as a separate step.

**Do not treat this scope as a fixed conclusion.** It's what dropping the plugin literally requires
mechanically. Whether that's still the right move, or the broader streamline-and-simplify
conversation points somewhere else (e.g. simplifying WHAT exists before WHERE it's packaged), is
exactly what this session is for.

## Recent adjacent precedent (same session, may be a useful reference point)
`PROGRESS.md` was just reconciled 1281→104 lines (commit `05e705d`): full content archived
verbatim to `docs/archive/PROGRESS-archive-2026-06-03-to-2026-06-30.md`, live file trimmed to true
one-liners, rotation policy recorded in `decisions/0022`. Same underlying philosophy as the
streamline direction — simplify the live surface, keep full fidelity one hop away, lose nothing.
Might be worth naming as a pattern for other places it could apply — `PLAN.md` (677 lines) has the
identical unbounded-growth shape, flagged in 0022, not yet acted on.

## One unrelated loose end from this session (owner-only, not part of the brainstorm)
`brain-capture` MCP server (`76d929ef...`) — decided prune-worthy 2026-06-23 (superseded by
memory-mcp), never actually removed. Not portal-fronted, not in `.mcp.json`, no repo source — a
bare claude.ai connector, no tool reaches it. Owner action whenever convenient: claude.ai →
Settings → Connectors → remove the one exposing `append_note/get_index/inbox_drop/list_notes/
read_note/search_notes/write_note`.

## Next
Wait for the owner to actually share their direction. Do not propose a repo-flattening plan, or
start executing anything, before that — this handoff is context, not a task list.

Live status is always [PLAN.md](../PLAN.md) / [PROGRESS.md](../PROGRESS.md), not this snapshot.
