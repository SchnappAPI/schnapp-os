---
name: session-hygiene
description: Use on surfaces WITHOUT hooks (claude.ai web/chat, iPhone, Cowork until verified) to run the must-happen session procedures that Claude Code does automatically via hooks — at the START of work (freshness/git gate: catch up, surface unmerged/unpushed/stale state before new work), when WRAPPING UP (end-of-session write: persist fresh memory + handoff, commit/push, back up), and right AFTER the owner corrects a mistake (route the fix to a rule/memory/doc so it can't recur). Invoke when starting or ending work on a hookless surface, or whenever a correction lands.
---

# session-hygiene

The "must happen every time" procedures, for surfaces where **hooks do not run**. On Code
(Mac + work machines) these are enforced deterministically by the Part-7.2 hooks
([`plugins/core/hooks/`](../../hooks/)). Here there is no shell/hooks, so the agent runs the
**same procedures** by hand. The procedures are authored **once** in
[docs/memory-lane.md](../../../../docs/memory-lane.md) — this skill does not restate them; it points
to each and adds the hookless-surface execution notes. Confirm what is actually loaded first
with [surface-check](../surface-check/SKILL.md).

## When to run which

| Moment | Procedure (canonical) | Hook equivalent on Code |
|---|---|---|
| Start of work | [Freshness gate](../../../../docs/memory-lane.md#freshness-gate-sessionstart) | `session-start-gate.sh` |
| Wrapping up | [End-of-session write](../../../../docs/memory-lane.md#end-of-session-write-stop--sessionend) | `session-end-backup.sh` |
| Owner corrects a mistake | [On-correction update](../../../../docs/memory-lane.md#on-correction-update-any-surface) | `session-stop-push-gate.sh` + the others |

## Hookless-surface execution notes (what differs from Code)

No local git, shell, filesystem, or `backup-archive.sh` here. Same intent, different mechanics:

- **Read git / repo state** (freshness gate step 4, unmerged/unpushed): use the **GitHub
  connector** (read the branch, commits, open PRs) instead of `git status`. Or call the Mac via
  its remote MCP. If neither is available, state that you could not verify and ask.
- **Persist memory / handoff / PROGRESS + "commit and push"** (end-of-session write, on-correction
  memory write): there is no local working tree. Write the file through the **GitHub connector**
  (`create_or_update_file` to `SchnappAPI/schnapp-os`), which commits and "pushes" in one step. If
  the connector is absent, **generate a ready-to-run prompt/patch** for a Code session and hand it
  to the owner (always-complete: never silently skip the write).
- **Back up** (end-of-session write): `backup-archive.sh` needs a shell and cannot run here. The
  repo write above already lands in git (the source of truth); for the chat transcript itself use
  export or the `live-session-cache` skill. Do not claim the OneDrive/Obsidian mirror ran — it runs
  from a Code/Mac session (the SessionEnd hook), not from here.
- **Route a correction** (on-correction update): classify and route per the
  [`learn-route`](../learn-route/SKILL.md) skill — preference → a [`rules/global/`](../../rules/global/)
  file; durable fact → memory **supersede** (`source: correction`, today's `updated:`); stale doc →
  fix the doc. Land each via the GitHub connector or a generated Code prompt.

## Always-loaded companion

The freshness gate and on-correction routing should be in context *before* the user asks, not
only on demand. On claude.ai/Cowork that means adding the global rules + a short pointer to this
skill as always-loaded project instructions (wired per surface in Part 10; see the
[surface profiles](../../../../surfaces/)). This skill is the on-demand workflow; the always-loaded
instructions are the standing reminder that these procedures exist on a surface with no hooks.
