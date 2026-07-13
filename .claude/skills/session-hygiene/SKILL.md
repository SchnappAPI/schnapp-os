---
name: session-hygiene
claude-ai-tier: core
description: Use on surfaces WITHOUT hooks (claude.ai web/chat, iPhone, Cowork) to run the must-happen session procedures that Claude Code does automatically via hooks - at the START of work (freshness/git gate: catch up, surface unmerged/unpushed/stale state before new work), when WRAPPING UP (end-of-session write: persist fresh memory + handoff, commit/push, back up), and right AFTER the owner corrects a mistake (route the fix to a rule/memory/doc so it can't recur). Invoke when starting or ending work on a hookless surface, or whenever a correction lands.
---

# session-hygiene

The "must happen every time" procedures, for surfaces where **hooks do not run**. On Code
(Mac + work machines) these are enforced deterministically by the Part-7.2 hooks
([`hooks/`](../../../hooks/)). Here there is no shell/hooks, so the agent runs the
**same procedures** by hand. The procedures are authored **once** in
[docs/memory-lane.md](../../../docs/memory-lane.md) - this skill does not restate them; it points
to each and adds the hookless-surface execution notes. Confirm what is actually loaded first
with [surface-check](../surface-check/SKILL.md).

## When to run which

| Moment | Procedure (canonical) | Hook equivalent on Code |
|---|---|---|
| Start of work | [Freshness gate](../../../docs/memory-lane.md#freshness-gate-sessionstart) | `session-start-gate.sh` |
| Wrapping up | [End-of-session write](../../../docs/memory-lane.md#end-of-session-write-stop--sessionend) | `session-end-backup.sh` |
| Owner corrects a mistake | [On-correction update](../../../docs/memory-lane.md#on-correction-update-any-surface) | `session-stop-push-gate.sh` + the others |

Start + stop together are the [handoff packet](../../../docs/memory-lane.md#handoff-packet-cross-surface-resume):
the same packet on every surface, only the transport differs (decisions/0027). Work stops by
writing it and starts by reading it, so a session begun on Code resumes on Cowork and back with
nothing lost.

## Hookless-surface execution notes (what differs from Code)

No local git, shell, filesystem, or `backup-archive.sh` here. Same intent, different mechanics:

- **Read git / repo state** (freshness gate step 4, unmerged/unpushed): use the **GitHub
  connector** (read the branch, commits, open PRs) instead of `git status`. Or call the Mac via
  its remote MCP. If neither is available, state that you could not verify and ask.
- **Persist memory / handoff / PROGRESS + "commit and push"** (end-of-session write, on-correction
  memory write): there is no local working tree. Write each file through the **GitHub connector**
  (`create_or_update_file`), which commits and "pushes" in one step. The packet spans BOTH repos:
  handoff + PROGRESS + plan-box to `SchnappAPI/schnapp-os`; working-memory facts + `MEMORY.md`
  index lines to `SchnappAPI/schnapp-vault` (schema: the vault's `agents.md`, CI-enforced). If
  the connector is absent, **generate a ready-to-run prompt/patch** for a Code session and hand it
  to the owner (always-complete: never silently skip the write).
- **Connector writes are read-modify-write.** `create_or_update_file` replaces the WHOLE file:
  fetch the current content, apply the change, put the full result back. Never blind-put an
  append or a box flip.
- **Handoff index without the generator**: `handoffs/README.md` is generated
  (`scripts/gen-handoff-index.sh`) and needs a shell this surface lacks. Emulate its output
  byte-for-byte: insert your line first in the list as
  `` - [`NNN`](NNN-slug.md) <the handoff's H1 text> (resume point)`` and strip the
  `` (resume point)`` suffix from the previous top line. CI freshness diffs the committed index
  against a fresh regen on the next push, so an emulation slip fails visibly instead of rotting
  (decisions/0027).
- **Back up** (end-of-session write): `backup-archive.sh` needs a shell and cannot run here. The
  repo write above already lands in git (the source of truth); for the chat transcript itself use
  the surface's export. Do not claim the OneDrive/Obsidian mirror ran - it runs
  from a Code/Mac session (the SessionEnd hook), not from here.
- **Route a correction** (on-correction update): classify and route per the
  [`learn-route`](../learn-route/SKILL.md) skill - preference → a [`rules/global/`](../../../rules/global/)
  file; durable fact → memory **supersede** (`source: correction`, today's `updated:`); stale doc →
  fix the doc. Land each via the GitHub connector or a generated Code prompt.

## Always-loaded companion

The freshness gate and on-correction routing should be in context *before* the user asks, not
only on demand. On claude.ai/Cowork that means adding the global rules + a short pointer to this
skill as always-loaded project instructions (wired per surface; see the
[surface profiles](../../../surfaces/)). This skill is the on-demand workflow; the always-loaded
instructions are the standing reminder that these procedures exist on a surface with no hooks.
