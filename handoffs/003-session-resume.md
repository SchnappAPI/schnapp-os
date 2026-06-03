# Handoff 003 — full session resume (start here in a fresh session)

Date: 2026-06-03. This is the master resume point. Open a fresh Claude Code session with
working dir `~/code/claude-kit`, read PLAN.md + PROGRESS.md + the latest handoffs, then go.

## What claude-kit is
Central, multi-surface Claude system replacing the sprawling schnapp-kit. Single source of
truth. PLAN.md = master plan (12 parts). PROGRESS.md = log. decisions/ = decisions.
Repo: `SchnappAPI/claude-kit` (PRIVATE), `main`, synced over SSH.

## Done and pushed
- Part 0: repo, tracker, SSH remote.
- Part 1: schnapp-kit frozen (tag `record-2026-06-03`), disabled + 12 redundant plugins;
  fleet 19 -> 6 (kept: caveman, github, superpowers, plugin-dev, pyright-lsp, frontend-design).
  schnapp-kit is now a source repo to dissect, not a plugin (decisions/0003).
- Part 2: global rules (plugins/core/rules/global/), surface profiles (surfaces/).
  NOT done: 2.2 (~/.claude/CLAUDE.md @import + symlink ~/.claude/rules/global) — do after install.
- Part 3: rule module gallery (plugins/core/rules/modules/, path-scoped lang modules),
  presets, /new-project composer. NOT done: 3.4 verify path-scoping (needs install/symlink test).
- Part 4 (partial): 1Password SA rotated, op/gh work everywhere op runs. OP_SERVICE_ACCOUNT_TOKEN
  Actions secret set on 8/10 repos. Decisions 0002/0004 recorded.

## Pending owner items
- Widen the GitHub fine-grained PAT to All repositories (or add `af-invoice-parser` and
  `af-query-api`), then set the token secret on those 2 (the rest are done).
- Choose connector host (decisions/0004): Worker+nodejs_compat (verify) vs Node host.

## Next, in order
1. Part 4.2: build the off-Mac 1Password connector (handoff 002 + decisions/0004). 1P SDK is
   Node-only; try Worker+nodejs_compat, verify it runs, else Node host. Auth it, register the
   HTTPS URL in claude.ai. Owner said "build the connector" first.
2. Part 5: two-lane memory (autoMemoryDirectory -> repo path, supersede-not-append, freshness
   gate, dual-altitude promotion).
3. Then Parts 2.2, 6 (OneDrive/Obsidian), 7 (hooks+skills enforcement, surface-check), 8 (git
   hygiene), 9 (anti-stale wiring), 10 (marketplace + install + wire surfaces), 11 (agentic OS).

## How to work (owner preferences — important)
- Direct, terse, no fluff, no em dashes, lead with the recommendation. Be quick.
- Never guess; verify files/tools/facts before asserting; flag uncertainty.
- Act autonomously; do not stop for hand-holding. Handoff at each Part boundary with a resume
  prompt. Commit + push every change.
- Git simplicity: work on main, no branches unless strong benefit + explicit approval.
- caveman mode (terse) is active via the caveman plugin; normal prose for code/commits/security.

## Gotchas
- schnapp-kit is disabled, so its skills/commands/hooks do NOT load. Use claude-kit + native
  built-ins. Migrate pieces from the schnapp-kit repo deliberately.
- Memories from the build session live in schnapp-kit's auto-memory dir and will NOT auto-load
  in a claude-kit-cwd session. This repo's PROGRESS/decisions/handoffs are the real continuity.
- settings.json backup: `~/.claude/settings.json.bak-20260603-144320`.

## Resume prompt to paste in the fresh session
"Resume claude-kit. Working dir is ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and
handoffs/003-session-resume.md first. Then build the off-Mac 1Password connector (Part 4.2,
decisions/0004 + handoff 002), then keep moving in order. Act autonomously, handoff at each
part boundary, commit and push."
