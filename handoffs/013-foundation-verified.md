# Handoff 013 — Foundation verify COMPLETE (supersedes 012). Tracker + docs current.

Date: 2026-06-05.

## What changed this session
**Foundation verify is DONE** — PLAN 2.4 / 3.4 / 5.6 all flipped to `[x]` with live evidence. This was
step 1 of the locked finish sequence (the base everything else builds on). Committed `ae9bba7`, pushed.

Method (reusable): faithful **headless `claude -p` sessions in a real second repo**. Verified against
Claude Code docs that headless, WITHOUT `--bare`, loads the SAME context as interactive — user
`~/.claude/CLAUDE.md` + its `@import`s, project `.claude/CLAUDE.md`, path-scoped `.claude/rules/*.md`, and
auto-memory. So `claude -p` in a throwaway composed repo is a true live-session check. Fixture
(`/tmp/ck-verify/repo-b`, python+sql-server module symlinks) was created, used, and removed.

- **2.4 global lane in another repo** — repo-b quoted the owner's unique rule `` `galPerUnitPerDay` not
  `gpud` `` verbatim with NO file read. That string is not general knowledge → the global lane loaded via
  `~/.claude/CLAUDE.md` in an unrelated, untrusted repo. User-scope config loads regardless of CWD/trust.
- **3.4 path-scoped non-leak** — read `.py` → python.md loaded (quoted `fetch_player_props()`) + `SQL-ABSENT`;
  read `.sql` → sql-server.md loaded (quoted the `_archive` vs `_backup` rule) + `PYTHON-ABSENT`. Native
  `paths:` frontmatter scoping loads a module only for matching files. Zero cross-language leak, both ways.
- **5.6 cross-repo memory + supersede** — repo-b loaded the real lane (quoted `keep-tracker-current` + a
  throwaway `VERIFY-ALPHA` token); after an IN-PLACE supersede to `VERIFY-BETA`, a fresh repo-b session saw
  `VERIFY-BETA` / `OLD: NO`, with one fact file + one index line. Supersede, not duplicate, cross-repo.

## Load-bearing delivery fix (do not lose this)
5.6 surfaced the only real gap: **cross-repo memory requires `autoMemoryDirectory` at USER scope.**
- A **plugin cannot** set `autoMemoryDirectory` (only `agent` / `subagentStatusLine` keys are
  plugin-settable) → Part-10 packaging can NOT deliver it. Verified via docs.
- A **project-scoped** setting reaches only that project (repo-b project-scope attempt → `LANE-ABSENT`,
  also gated by workspace trust).
- So the global memory lane is delivered the same way as the global RULES lane: **user scope**. Owner
  approved adding `"autoMemoryDirectory": "~/code/claude-kit/memory"` to `~/.claude/settings.json`
  (2026-06-05). This is now a **per-machine install step** — README "Code — primary Mac" step 2.
- claude-kit's existing project-scoped `autoMemoryDirectory` (in its `.claude/settings.json`) is now
  redundant but LEFT as a benign self-contained bootstrap fallback (same value, same dir, cannot drift).
- Ripple fixed in the same pass: README step 3's old claim that the memory lane "silently does nothing
  until trust" is corrected — user-scope memory loads regardless of trust; trust gates the project hooks.

## Where we are (locked finish order — see PLAN.md "Finish sequence")
1. **Foundation verify — DONE** (this session). ✅
2. **Capability layer (C.0–C.3) — NEXT, not started.** ← resume here.
3. Part 10 — package + wire surfaces (plugin delivers global gate+push-gate; strip the dup from project
   settings.json — explicit owner approval; decisions/0005).
4. Part 11 — agentic OS capstone.
5. Final 14-point verification sweep.

State by Part unchanged from 012 except: 2.4/3.4/5.6 now `[x]`. Parts 0,1,4,9 done; Part-7 hooks
live-verified; 5.5 `[~]`, 6.2/6.3 `[~]` (Obsidian, owner GUI), 7.x per-surface enablement + 8.3 close at
Part 10 / first branch.

## Next phase: Capability layer (C.0 first — never build blind)
Owner scope = **DOMAIN-FIRST LEAN** (decisions/0006). C.0 = gap inventory: for each candidate capability,
check whether it ALREADY exists in (a) keep-set plugins (superpowers/caveman/plugin-dev/frontend-design),
(b) available skills (anthropic-skills: pq-flat-map-type / fish-compare / sports-data-auditor / xlsx / pdf
/ docx; the `data:*` suite; `design:*`; deep-research), (c) MCP connectors (op-mcp / Mac-ops / GitHub /
Cloudflare). EXISTS → compose/reference (name it in the right preset + surface profile), do NOT rebuild.
Build only the genuine gap. Record the inventory in `decisions/`. Candidate gap set (confirm against C.0):
`etl-pipeline-build` skill, `sql-server-patterns` skill, `/update-docs` (+`/update-codemaps`) for the
owner's OTHER ETL repos, grow `tool/quickbase`+`tool/appfolio` only if no env skill covers them
(fish-compare already does AppFolio), 0–2 domain agents. Then C.2 (extend presets + regenerate CATALOG)
and C.3 (schnapp-kit stays the on-demand archive). schnapp-kit frozen at `~/code/schnapp-kit`, tag
`record-2026-06-03` (134 skills / 39 agents / 59 commands / 21 hooks) — the archive to pull from, never bulk-migrate.

## Gotchas (carry forward)
- **CATALOG is generated.** After adding/removing ANY rule/skill/command/hook, run
  `plugins/core/scripts/gen-catalog.sh` and commit `plugins/core/CATALOG.md` (freshness CI enforces).
  Keep the generator cross-platform (CI uses `mawk`): literal bytes via `-v`, `LC_ALL=C`, no gawk-only / awk `\x` escapes.
- **`.gitignore` secret-globs** (`**/*secret*`) silently exclude files whose name contains "secret";
  there is a `!**/secrets-as-references.md` negation — a future such file needs its own.
- Hooks/settings load at session start → changes need a restart. `~/.claude` / settings.json changes need
  **explicit** owner approval (a clarifying question is not consent).
- `${CLAUDE_PLUGIN_ROOT}` is the only portable global HOOK delivery (Part 10); `autoMemoryDirectory` is
  NOT plugin-deliverable (user settings only — see above).
- Before restructuring anything other docs reference (e.g. Part numbers), check blast radius; prefer stable identifiers.
- `~/.claude/CLAUDE.md` content lives canonically in `templates/user-global-CLAUDE.md`. The `~/.claude/
  settings.json` `autoMemoryDirectory` requirement is documented in the README install checklist (no full
  settings template — the rest of that file is machine-specific).

## Resume prompt
"Resume claude-kit. Working dir `~/code/claude-kit`. Read PLAN.md ('Finish sequence' + 'Capability layer'),
PROGRESS.md, decisions/0006, and handoffs/013-foundation-verified.md FIRST — tracker + docs current.
Foundation verify (2.4/3.4/5.6) is DONE; the global memory lane is now delivered at user scope
(`~/.claude/settings.json` autoMemoryDirectory). Next phase, in the locked order, is the **Capability
layer**: do **C.0 gap-inventory FIRST** (for each candidate, check keep-set plugins / available skills
[anthropic-skills, data:*, design:*, deep-research] / MCP connectors; COMPOSE-not-rebuild what exists;
record the inventory in decisions/), then C.1 build ONLY the genuine gap (domain-first lean,
owner-confirmed), C.2 extend presets + regenerate CATALOG (gen-catalog.sh, CI enforces), C.3 leave
schnapp-kit as the on-demand archive. Then Part 10 (package + wire surfaces; plugin delivers global hooks
per 0005, then strip the dup from project settings.json — explicit owner approval), Part 11 (agentic OS),
final 14-point sweep. Binding rules: think in systems / trace each change's ripple; work from the objective;
build only the gap, compose what exists; verify load-bearing assumptions first; fix the class not the
instance; do NOT escalate decisions the locked plan settles. keep-tracker-current (flip box + PROGRESS line
+ push every state change; gen-catalog after any rule/skill/command/hook change). Explicit owner approval
before any `~/.claude` / settings.json / secret change. Act autonomously; pause at Part boundaries."
