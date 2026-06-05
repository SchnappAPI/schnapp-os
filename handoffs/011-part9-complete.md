# Handoff 011 — Part 9 complete; Part-7 hooks live-verified (supersedes 010). Tracker + docs current.

Date: 2026-06-05.

## TL;DR
- **Part-7 hooks LIVE-VERIFIED** this session → flipped **5.3 / 5.4 / 8.2 → [x]**. The SESSION-START
  GATE printed at startup (proves the workspace-trust dialog is accepted), the Stop push-gate BLOCKED a
  commit held unpushed then allowed after `git push`, and the SessionEnd backup deliverable ran green.
- **Part 9 COMPLETE (9.1–9.5 all [x]).** Anti-staleness wiring is live: a generated CATALOG, a CI
  freshness gate that is GREEN on GitHub, a project-CLAUDE template, and a per-surface README install
  checklist.
- The freshness gate **paid off immediately**: caught a cross-platform generator bug AND a real
  correctness bug (a core global rule was untracked). Both fixed; CI green (run 27034142430, 62cc695).
- Next, in order: **Part 10** (wire surfaces; the marketplace plugin delivers the global hooks per
  decisions/0005; this also closes the long-pending verifies 2.4 / 3.4 / 5.6 / 7.x enablement).

## What Part 9 added (all pushed, tree clean)
- **9.2** `plugins/core/scripts/gen-catalog.sh` → generates `plugins/core/CATALOG.md`, an inventory of
  global rules / modules-by-dimension (with path scope) / presets-linked / skills / commands / hooks.
  Marked "generated — do not edit"; deterministic (C-locale sort, no timestamps) so CI can diff it.
  ("update-codemaps" N/A — no code graph in a docs/config repo; "update-docs" = this generator.)
- **9.1 + 9.4** `templates/project-CLAUDE.md` (thin composed project CLAUDE.md that REFERENCES canonical
  sources, copies no rule content; globals load via `~/.claude/CLAUDE.md`, modules via `.claude/rules/`
  symlinks — NOT re-imported, that double-loads). `/new-project` now writes from it and the old
  "@import globals or note them" ambiguity is resolved to note-only. Dedup sweep: no living doc
  paraphrases a rule body.
- **9.3** `.github/workflows/freshness.yml` (GitHub-hosted ubuntu, Mac-independent, fetch-depth 0) runs
  `plugins/core/scripts/check-freshness.sh`: (1) regenerate CATALOG + fail if the committed copy is
  stale; (2) flag any `last-verified:` doc whose `sources:` changed later per git log (no-op until
  adopted). Verified 4 cases locally + **live CI GREEN**.
- **9.5** README "Install (per surface)" — Code (Mac + other machines), Cowork, claude.ai web, iPhone —
  with the workspace-trust step, OneDrive backup path, and the 0005 hook-delivery split. The
  `~/.claude/CLAUDE.md` content is single-sourced as tracked `templates/user-global-CLAUDE.md`. README
  Map + "Staying current" CI line updated.

## Two real bugs the freshness gate surfaced (now fixed)
1. **Cross-platform generator non-determinism** — `gen-catalog.sh` emitted `…` via an awk `\xe2\x80\xa6`
   hex escape; the CI runner's `mawk` does not interpret it like the mac's BSD awk, so 3 truncated skill
   lines diverged. Fix: pass the ellipsis as a literal byte string via `awk -v ell='…'`.
2. **A core global rule was untracked** — `.gitignore` `**/*secret*` matched
   `plugins/core/rules/global/secrets-as-references.md`, so one of the 7 ALWAYS-LOADED global rules was
   present locally (it is `@import`ed by `~/.claude/CLAUDE.md`) but ABSENT from GitHub / CI / any cloned
   machine, where it would silently fail to load. Fix: targeted `.gitignore` negation
   `!**/secrets-as-references.md` + committed the rescued file. (Audited all ignored files — it was the
   only false positive.)

## State by Part
- **0, 1, 4, 9** DONE. **2**: 2.4 verify pending (Part 10). **3**: 3.4 verify pending (Part 10).
- **5**: 5.1/5.2 done; **5.3/5.4 now [x]** (live-verified); 5.5 `[~]`; 5.6 pending (Part 10).
- **6**: 6.1 done; 6.2 `[~]` (MacBook: open `claude-archive` in Obsidian + Local REST API); 6.3 pending.
- **7**: authored + wired; scope resolved (0005); **hook live-verify DONE this session**. Still open:
  `8.2`-style closes; remote `http`/`mcp_tool` hooks; Cowork-runs-hooks check; per-surface enablement +
  **plugin global delivery (Part 10)** — 7.2 formally closes there.
- **8**: 8.1 `[x]`; **8.2 now [x]**; 8.3 `[~]` (until an approval-gated branch exists).
- **10, 11**: not started.

## Owner / next-session items
- **4.2 redeploy** (propagate the tool-description tweaks, functionally already works): Render → op-mcp →
  Manual Deploy `15e197d`+, then Cloudflare MCP server re-sync.
- **6.2/6.3:** MacBook — open `claude-archive` as an Obsidian vault + install the Local REST API plugin.
- **Actions secret:** decide on `DB_Storage` + `appfolio-marketing-project` (never scoped).
- **Part-10 verifies that have been waiting:** 2.4 (global lane loads in another repo), 3.4 (path-scoped
  non-leak: Python rules absent when editing `.sql`), 5.6 (cross-repo lesson + supersede).

## Gotchas
- **CATALOG is generated:** after adding/removing a rule, skill, command, or hook, run
  `plugins/core/scripts/gen-catalog.sh` and commit `plugins/core/CATALOG.md`, or the freshness CI fails.
- **Keep the generator cross-platform** (CI uses `mawk`): no awk `\x` escapes (pass literal bytes via
  `-v`), keep `LC_ALL=C`, avoid gawk-only features. A freshness failure now PRINTS the diff.
- **`.gitignore` secret globs** (`**/*secret*`) silently exclude any doc whose name contains "secret".
  There is now a `!**/secrets-as-references.md` negation; a future such doc needs its own negation.
- Hooks load at session start — editing hooks/settings needs a **restart**. `.claude/settings.json` hook
  changes need **explicit** owner approval (a clarifying question is not consent).
- `${CLAUDE_PLUGIN_ROOT}` is the only portable global-hook delivery (Part 10). No absolute `~/.claude`
  hook paths (machine-bound; violates single-source — decisions/0005).
- `~/.claude/CLAUDE.md` content now lives canonically in `templates/user-global-CLAUDE.md`.
- `connectors/op-mcp/` `node_modules`+`dist` gitignored (`npm install` before build).
- settings.json backup: `~/.claude/settings.json.bak-20260603-144320`.

## Next buildable, in order
1. **Part 10** — wire surfaces + final verification. 10.1: make `claude-kit` a marketplace
   (`.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`), install in Code so
   the plugin's `hooks/hooks.json` delivers the global gate+push-gate everywhere (then REMOVE the
   gate+push-gate from the project `.claude/settings.json` to avoid double-fire, keeping ONLY the
   backup — decisions/0005); connect the repo in Cowork; add core skills + the connector in claude.ai.
   10.2: run the full verification list (closes 2.4, 3.4, 5.6, and the 7.x per-surface enablement).
2. **Part 11** — agentic OS layer (scheduler, `/do` orchestrator, `status` control plane).

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and
handoffs/011-part9-complete.md first — tracker + docs are current. Parts 0–9 are done; the Part-7 hooks
are live-verified (5.3/5.4/8.2 [x]) and the Part-9 anti-staleness wiring is complete with a GREEN CI
freshness gate. Continue strict IN-ORDER to **Part 10** (wire surfaces + final verification): 10.1 make
claude-kit a marketplace plugin (.claude-plugin/marketplace.json + plugins/core/.claude-plugin/plugin.json),
install in Code so the plugin delivers the global gate+push-gate everywhere via ${CLAUDE_PLUGIN_ROOT},
then REMOVE those two from the project .claude/settings.json to avoid double-fire — keep ONLY the backup
(decisions/0005); connect the repo in Cowork; add the core skills + op-mcp connector in claude.ai. 10.2
run the full verification list, which also closes the waiting verifies 2.4 (global lane in another repo),
3.4 (path-scoped non-leak), 5.6 (cross-repo lesson + supersede). Behavioral rules are loaded and binding:
think in systems and trace each change's ripple across docs/trackers/surfaces; work from the objective,
not the literal ask; fix the class not the instance; do NOT escalate decisions the locked plan already
settles — resolve from the plan, act, record. Apply keep-tracker-current (flip box + PROGRESS line + push
every state change; no doc hardcodes a mutable fact). After adding/removing any rule/skill/command/hook,
run plugins/core/scripts/gen-catalog.sh and commit CATALOG.md or the freshness CI fails. Get explicit
owner approval before any ~/.claude / settings.json hook change or secret distribution. Act autonomously;
handoff at each Part boundary. Pause occasionally to check for input."
