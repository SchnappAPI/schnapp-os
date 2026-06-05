# 0005 — Hook delivery: plugin-global vs claude-kit-project split (2026-06-05)

Goal: the Part-7 "must happen" hooks run on **every Code project on every machine**, per PLAN 7.2
("hooks for Code on all machines") and the kernel objective (one central system, not Mac-bound or
repo-siloed).

## The problem found (2026-06-05)
The three hooks were activated by wiring `claude-kit/.claude/settings.json`. Project settings fire
**only when the working directory is the claude-kit repo**. So the project-agnostic hooks (the
SessionStart gate + the Stop push-gate) do **not** run in the owner's other repos — 7.2's "all
machines/projects" intent is not met by that wiring. Three coupled issues:
1. **Scope:** global behaviors wired project-locally → claude-kit-only.
2. **Double-fire:** Part 10 installs claude-kit as a plugin; the plugin's `hooks/hooks.json`
   re-delivers the same hooks. With both present they fire twice in the claude-kit repo.
3. **Wrong-scope backup:** `backup-archive.sh` mirrors the **claude-kit** knowledge base. If it were
   delivered globally it would back up claude-kit at the end of *every* unrelated session.

## Resolution (dictated by the locked decisions, not an open choice)
The locked architecture already answers this: claude-kit IS a marketplace **plugin** and the single
source of truth; nothing is machine-bound or siloed. Therefore:

- **Project-agnostic hooks (SessionStart gate + Stop push-gate) → delivered by the PLUGIN.** The
  plugin's `plugins/core/hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}`, which resolves wherever the
  plugin is installed, so once Part 10 installs claude-kit (Code, all machines) these fire for every
  session in every repo. This is the only delivery consistent with single-source + no-siloing.
- **claude-kit-specific backup (`session-end-backup.sh` → `backup-archive.sh`) → stays project-scoped**
  to the claude-kit repo's `.claude/settings.json`. It mirrors claude-kit's own knowledge base; it
  must not run from unrelated repos. (Its `CLAUDE_KIT_REPO` default/override already points at the
  knowledge base regardless of cwd, but it should only be *triggered* from claude-kit.)
- **`~/.claude/settings.json` global hooks: rejected.** Absolute claude-kit paths in user settings
  would work on one Mac but are machine-bound and non-portable — a direct violation of the
  single-source / no-siloing decisions. The plugin is the portable delivery.

## Avoiding the double-fire (executed at Part 10, recorded here so it is deterministic)
When Part 10 installs the plugin, **remove the SessionStart gate + Stop push-gate from
`claude-kit/.claude/settings.json`**, leaving only the SessionEnd backup there. The plugin then owns
the two global hooks (everywhere, including claude-kit); the project settings own only the backup. No
hook is wired in two places, so nothing double-fires.

## Until Part 10 (current state)
The claude-kit project wiring of all three hooks stays as **dev-time dogfood**: it exercises the gate
+ push-gate + backup in the repo we work in most, so they are proven before Part 10 makes them global.
This is intentionally claude-kit-only and is NOT "7.2 complete" — 7.2 closes when the plugin delivers
the global hooks at Part 10.

## Prerequisite that gates all of the above
Hooks (and `autoMemoryDirectory`, 5.1) take effect only **after the per-machine workspace-trust
dialog is accepted**. An unaccepted trust dialog silently nullifies every hook and the memory lane.
This is an explicit live-verify step (handoff 009) and an install-checklist item (9.5), not an
assumption.
