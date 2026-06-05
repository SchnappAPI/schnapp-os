# Handoff 012 — mid-build evaluation + locked finish plan (supersedes 011). Tracker + docs current.

Date: 2026-06-05.

## The objective (hold this; it drives every remaining decision)
ONE understood, multi-surface Claude system that REPLACES the old 19-plugin sprawl: single source of
truth, composable rules, two-tier cross-surface memory, credentials everywhere, anti-staleness,
must-happen hooks, AND a DELIBERATELY-CHOSEN, growing set of productive skills/commands/agents for the
owner's ACTUAL platform — usable identically on Code (all machines), Cowork, claude.ai, iPhone. Grown
deliberately, never sprawling. The owner left schnapp-kit because of sprawl (19 plugins, ~4 overlapping
memory systems). So "complete" means capable AND lean — not "port all 134 skills."

## Are we on track? YES for the foundation; the gap was a missing phase (now added)
A 3-way parallel evaluation this session found:
1. **Foundation VERIFIED SOUND** (the big de-risk). `.claude/rules/` auto-discovery + `paths:` frontmatter
   scoping is NATIVE in current Claude Code (confirmed vs code.claude.com/docs/en/memory.md +
   plugins-reference). The composition design (symlink modules into `<project>/.claude/rules/`,
   path-scoped) holds — NO architectural rework. Plugin components auto-discover by directory; the
   manifest is metadata-only. So verifies 2.4/3.4/5.6 are confirmations, not risk-gates.
2. **claude-kit is cohesive through Part 9** — no orphans, no dead files, no stale cross-refs. Only the
   Part-10 plugin manifests and an `agents/` dir are absent (both expected).
3. **The real gap** the owner felt: claude-kit has 3 skills / 1 command / 0 agents (ALL infrastructure).
   schnapp-kit (frozen, `~/code/schnapp-kit`, tag `record-2026-06-03`) has 134 skills / 39 agents / 59
   commands / 21 hooks. The plan had NO phase to select + build the PRODUCTIVE capability layer. Fixed:
   added a Capability-layer phase (decisions/0006).

## Owner decisions (2026-06-05)
- **Capability scope = DOMAIN-FIRST LEAN.** Build ONLY what serves the owner's platform AND is not already
  provided by the keep-set (superpowers/caveman/plugin-dev/frontend-design), the available skills
  (anthropic-skills, `data:*`, `design:*`, deep-research), or the MCP connectors. Compose what exists;
  schnapp-kit stays an on-demand archive (no bulk migration). Anti-sprawl.
- **Finish the agentic OS (Part 11) as the capstone** — but LAST.

## Locked finish order (authoritative — see PLAN.md "Finish sequence")
Do earlier-listed FIRST (avoids rework). Part numbers kept STABLE (no renumber ripple).
1. **Foundation verify** (cheap confirmations): 2.4 (global lane in another repo), 3.4 (path-scoped
   non-leak — now native-confirmed), 5.6 (cross-repo memory + supersede). Needs a 2nd repo + 1-2 live
   sessions. DO FIRST.
2. **Capability layer** (NEW phase, PLAN "C.0–C.3"): C.0 gap-inventory FIRST (never build blind — check
   keep-set/available-skills/connectors; compose what exists), C.1 build only the gap (candidates:
   `etl-pipeline-build`, `sql-server-patterns` skills; grow `tool/quickbase`/`tool/appfolio` only if no
   env skill covers them — fish-compare already does AppFolio; `/update-docs`+`/update-codemaps` for the
   owner's OTHER repos; 0–2 domain agents), C.2 extend presets + regenerate CATALOG, C.3 schnapp-kit =
   on-demand archive. BEFORE packaging, so the plugin ships complete.
3. **Part 10 — package + wire surfaces:** marketplace.json + plugin.json; install in Code so the PLUGIN
   delivers the global gate+push-gate (`${CLAUDE_PLUGIN_ROOT}`), then REMOVE those two from project
   `.claude/settings.json` (keep ONLY backup — decisions/0005); wire Cowork/claude.ai/iPhone + per-surface
   skill enablement (closes 7.3/7.4/7.5).
4. **Part 11 — agentic OS capstone:** scheduler, `/do` orchestrator, `status` control plane.
5. **Final 14-point verification sweep** → production-ready.

## State by Part
- **0,1,4,9 DONE.** **Part-7 hooks live-verified** this session (5.3/5.4/8.2 = `[x]`).
- **2**: 2.4 verify pending (step 1). **3**: 3.4 verify pending (step 1; mechanism now native-confirmed).
- **5**: 5.1/5.2/5.3/5.4 done; 5.5 `[~]` (opportunistic); 5.6 pending (step 1).
- **6**: 6.1 done; 6.2/6.3 `[~]` (owner MacBook: Obsidian + Local REST API).
- **7**: authored + wired; hook live-verify DONE; per-surface enablement + plugin global delivery close in
  Part 10; remote `http`/`mcp_tool` hooks + Cowork-runs-hooks check still open.
- **8**: 8.1/8.2 `[x]`; 8.3 `[~]` (until an approved branch exists).
- **Capability layer**: not started (the gap). **10, 11**: not started.

## Owner-gated parallel tracks (any time, non-blocking)
- 6.2/6.3 Obsidian (MacBook GUI: open `claude-archive` as a vault + Local REST API plugin).
- 4.2 connector redeploy (Render Manual Deploy `15e197d`+ then Cloudflare MCP re-sync; functionally works).
- Actions secret decision: `DB_Storage` + `appfolio-marketing-project` (never scoped).

## Gotchas (read before building)
- **CATALOG is generated.** After adding/removing ANY rule/skill/command/hook, run
  `plugins/core/scripts/gen-catalog.sh` and commit `plugins/core/CATALOG.md`, or the freshness CI fails.
- **Keep the generator cross-platform** (CI uses `mawk`): no awk `\x` escapes (pass literal bytes via
  `-v`), keep `LC_ALL=C`, avoid gawk-only features. A freshness failure prints the diff.
- **`.gitignore` secret-globs** (`**/*secret*`) silently exclude any file whose name contains "secret".
  There is a `!**/secrets-as-references.md` negation; a future such file needs its own negation (the CI
  freshness gate already caught one untracked global rule this way).
- **Rules loading is native** (verified): `.claude/rules/*.md` auto-load; no-`paths:` rules load always,
  `paths:` rules load only for matching files; symlinks supported. The composition design is correct.
- Hooks load at session start — settings/hook changes need a **restart**. `.claude/settings.json` hook
  changes need **explicit** owner approval (a clarifying question is not consent).
- `${CLAUDE_PLUGIN_ROOT}` is the only portable global-hook delivery (Part 10); no absolute `~/.claude`
  hook paths (machine-bound; decisions/0005).
- Before restructuring anything other docs reference (e.g. Part numbers), check the blast radius and
  prefer stable identifiers — caught + reverted a renumber that would have rippled this session.
- `~/.claude/CLAUDE.md` content lives canonically in `templates/user-global-CLAUDE.md`.
- `connectors/op-mcp/` `node_modules`+`dist` gitignored. settings.json backup:
  `~/.claude/settings.json.bak-20260603-144320`.

## Resume prompt
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md (esp. the 'Finish sequence' + 'Capability
layer' sections), PROGRESS.md, decisions/0006, and handoffs/012-evaluation-and-finish-plan.md FIRST —
tracker + docs are current. Parts 0–9 done; Part-7 hooks live-verified; foundation verified native-sound;
the finish order is LOCKED. Work strictly in this order, handing off at each boundary: (1) FOUNDATION
VERIFY — 2.4 (global lane loads in a second repo), 3.4 (path-scoped non-leak: open a composed project, edit
a .py vs a .sql, confirm Python rules do NOT load for .sql and vice versa), 5.6 (a lesson saved in repo A
appears in a fresh session in repo B; a changed fact supersedes, not duplicates). Use a real second repo;
these are live-session checks. (2) CAPABILITY LAYER (PLAN C.0–C.3): C.0 gap-inventory FIRST — for each
candidate capability check whether it already exists in the keep-set plugins / available skills
(anthropic-skills, data:*, design:*, deep-research) / MCP connectors, and COMPOSE-not-rebuild what exists;
only build the genuine gap (domain-first lean, owner-confirmed). Record the inventory in decisions/. C.1
build the gap lean into the gallery; C.2 extend presets + regenerate CATALOG (gen-catalog.sh, CI enforces);
C.3 leave schnapp-kit (~/code/schnapp-kit) as the on-demand archive. (3) Part 10 package + wire surfaces
(plugin delivers global hooks per decisions/0005; then REMOVE the gate+push-gate from project
.claude/settings.json — needs explicit owner approval). (4) Part 11 agentic OS. (5) final 14-point sweep.
Binding rules: think in systems and trace each change's ripple (check blast radius before renaming/
renumbering; prefer stable identifiers); work from the objective not the literal ask; build only the gap,
compose what exists, never recreate sprawl; verify load-bearing assumptions before building on them; fix
the class not the instance; do NOT escalate decisions the locked plan already settles. keep-tracker-current
(flip box + PROGRESS line + push every state change; after any rule/skill/command/hook change run
gen-catalog.sh and commit CATALOG.md). Explicit owner approval before any ~/.claude / settings.json hook
change or secret distribution. Act autonomously; pause at Part boundaries to check for input."
