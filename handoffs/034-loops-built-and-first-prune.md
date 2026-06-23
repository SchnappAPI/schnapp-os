# Handoff 034 — Plan review + both loops built + first prune (2026-06-23)

Supersedes 033 as the resume pointer. This session executed the decision doc's full order of
operations (`docs/schnapp-os-research-and-decisions-2026-06-23.md` §7.4) in one pass.

## IMMEDIATE next-session check (do this first)
The freshness gate and capture trigger are wired but only **run-verified**, not yet **live**-proven
(hooks load at session start, so they did not fire mid-session this session). At the next fresh
session start, confirm:
1. The SessionStart gate prints `===== schnapp-os SESSION-START GATE =====` (NOT `claude-kit`) with
   a clean `[sync] origin/main: ...`, git/memory/satellite state, and `[creds] 1Password SA resolves`.
   If a second stale `claude-kit` gate ALSO fires, the dead plugin registration needs busting (below).
2. A correction in your message triggers the `[capture]` route-it nudge (test: say "you're wrong").

## What happened (the order, all committed + pushed to origin/main)
- **Plan review** — all 10 load-bearing plan decisions re-decided on purpose → `decisions/0011`.
  PLAN.md reframed as a parking lot (not the spine); the decision doc governs. Commit f0de18d.
- **Capture intent** — `docs/intent-capture-2026-06-23.md` (5 parallel investigators mapped every
  component: load-bearing vs accretion, prune/defer candidates). Commit b5188a8.
- **Freshness gate (loop 1)** — `session-start-gate.sh`: fixed the sync bug (bare `git pull --ff-only`
  → explicit `git pull --ff-only origin "$branch"`; the bare form failed "Cannot fast-forward to
  multiple branches" and silently lost the decision doc) + added a 1Password reconcile. Moved ALL
  three hooks off the fragile plugin into `.claude/settings.json` (live `${CLAUDE_PROJECT_DIR}` paths);
  plugin `hooks.json` emptied; decision 0005 annotated SUPERSEDED. Commit 4895b31.
- **Learning loop capture-and-route (loop 2)** — `capture-nudge.sh` (UserPromptSubmit): the missing
  TRIGGER. High-precision grep for correction language → nudges routing per `memory/README`
  on-correction. Demonstrated by routing the owner's "fix on sight, don't ask" → a new bullet in
  `working-style.md`. Commit 8a652c1.
- **Prune (first cut)** — cut 4 skills on verified grounds (token-budget-advisor, strategic-compact,
  cost-aware-llm-pipeline, benchmark-optimization-loop); kept the rest (owner challenged the list,
  verified per-item). Fixed 5 live refs, regenerated CATALOG (26→22), freshness green. Commit 3c7fbea.

## The owner's vision (hold this)
A personal **agentic OS delivered through remote MCP servers**, consistent across ALL surfaces
(Code on Mac + machines, claude.ai web, Cowork, iPhone), no per-surface rebuild. GitHub origin =
source of truth; every surface reconciles to it. Two loops are the core (loops before features;
subtract, don't complete; plain over elaborate). ~1s hooks are fine — do NOT over-optimize.
Operationally: **fix defects/stale data on sight, don't ask; reserve questions for genuine forks.**

## Deferred (per the re-decisions — NOT done, each its own step)
- **Cross-surface freshness = the remote-MCP layer** (memory + control-plane scoped servers). This is
  how hookless surfaces stay consistent. The single biggest remaining piece of the vision. (0011 #5/#6)
- **#2 plainer repo** — flatten `plugins/core/` packaging. Note: hooks already moved off the plugin,
  so this is now safe-ish, but skills/rules/commands still deliver via the plugin.
- **#4 rules simplification** — drop the module gallery / presets / `/new-project` symlink composer;
  keep the real rule content (esp. `lang/sql-server.md` locked table rules) + the "project lane" idea.
- **#3 surface narrowing**, **#8 agentic-OS layer** (scheduled-tasks/`/do`), **force-push guard #9**.
- **Eval/promote gate** for the learning loop (doc §7.8) — required before any autonomous self-edits.

## Owner action items (outside the repo)
- Chat-memory feature: delete history + generation OFF in the Claude app (#10).
- Open credential rotations: owner-console set (GITHUB_PAT, Anthropic, Claude-OAuth, DB sa, Web App
  incl. RUNNER_API_KEY, Webshare, Cloudflare); 2 client bearer legs (claude.ai mac-mcp, Copilot
  github-mcp); `rm` the plaintext `…macmcp.plist.bak`; 28-file obsidian-vault leak scrub.
- Dead plugin registrations in `~/.claude` (`claude-kit-core@claude-kit`, `schnapp-kit`) — clean via
  `/plugin` (interactive). ~~Cosmetic now (the gate no longer depends on the plugin).~~
  **CORRECTED 2026-06-23 (handoff 035): NOT cosmetic, and now DONE.** The live plugin
  `claude-kit-core@schnapp-os` was pinned at an old commit whose bundled `hooks.json` still declared
  the SessionStart gate; the desktop local-agent harness snapshots from the pinned commit, so the
  stale `claude-kit` gate fired every session and its bare `git pull` raced the project gate
  ("Cannot fast-forward to multiple branches"). Fixed: re-pinned `@schnapp-os` to HEAD (empty hooks),
  removed both dead registrations + the dead `schnapp-kit` marketplace. See
  [[plugin-registry-snapshot-gotchas]]. Verifies at next restart (single clean gate).

## Resume primer (paste to start the next session)
> Load schnapp-os. Read handoffs/034 first. Confirm the SessionStart gate fired as `schnapp-os`
> (not claude-kit) with a clean sync + `[creds] 1Password SA resolves`, and that a correction
> triggers the `[capture]` nudge — that live-proves both loops. Then pick the next deferred step:
> the remote-MCP cross-surface layer (memory/control-plane servers) is the highest-value piece of
> the vision; #4 rules-simplification and #2 repo-flattening are the next cleanups. Fix stale/defects
> on sight; don't ask permission to fix what's known broken.
