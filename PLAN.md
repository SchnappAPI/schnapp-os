# Rebuild: a central, multi-surface Claude system

## Context

schnapp-kit grew into a sprawling plugin you no longer fully understand. The real cost is
19 enabled plugins plus a team-style hook autopilot. You want to start fresh from an
understood core and grow deliberately. Nothing is deleted: the old repo is frozen as a
recoverable record.

This is not a Claude Code plugin. It is a **central system of skills, commands, hooks,
agents, composable rules, memory, and credentials usable on every surface** (Code on all
your machines, Cowork, claude.ai web/chat, iPhone). One source of truth, no duplication,
nothing siloed, nothing stale, credentials always available, readable across surfaces.

This file is committed to the new repo as `PLAN.md` (globally accessible). `PROGRESS.md`
logs every step. `decisions/` logs every decision.

## Locked decisions

- New clean repo (`claude-kit`); old repo frozen as the record.
- **Always-complete, never degraded:** if a surface cannot do something natively, it does it
  via a remote MCP, or hands you a ready-to-run prompt. The surface never blocks you.
- Memory is two-tier (global + project) AND both lanes cross machines, repos, and cloud.
- Single source of truth, `@import` live files, generate derived docs, never duplicate.
- **Rules are composable modules from a gallery**, organized by four dimensions
  (language/stack, activity, context, global). Projects compose via **presets plus free
  pick**. Never locked into one set.
- **Git: simplicity.** Work on `main`, commit and push every change, log decisions and
  learnings. No branches unless strong benefit and explicit approval. Unmerged work is
  addressed before any new work next session.
- **Local and GitHub stay synced automatically:** pull `--ff-only` at session start, push on
  commit, surface divergence before work.
- Cloud backup of sessions, chats, memory, context to a OneDrive folder, mirrored into
  Obsidian on the Mac.
- Credentials resolve through 1Password on each surface, not routed through one machine.
- **Use what already exists; verify and extend, do not recreate.**

## Execution discipline (how we run this)

- **Act autonomously.** Do every step you can without stopping. Stop only for owner-only
  steps, explicit approvals, or a planned handoff boundary.
- **Handoff at each Part boundary.** Write `handoffs/NNN-<part>.md` to the repo (state,
  what changed, what is next, references to all notes/memory/decisions), commit and push,
  then give a ready-to-paste prompt to start the next session. No context is lost.
- **Everything to the repo.** Notes, memory, decisions, handoffs are committed, never left
  in a transient location.
- **Surface better options, do not force choices.** Apply sensible defaults and presets; if
  a better module or approach is detected, say so once, do not silently overlook it.

## How each worry maps to a fix

| Worry | Fixed by |
|---|---|
| Boxed into work vs personal | Four-dimension module gallery + presets + free pick (Part 3) |
| Rewriting rules from scratch | Seeded gallery of your own rules, ready to compose (Part 3) |
| JS conventions leaking into Python | Path-scoped rules load only for matching files (Part 3) |
| Lessons siloed per repo | Two-tier memory + dual-altitude promotion (Part 5) |
| Memory siloed per machine / cloud | Git-tracked memory both lanes + OneDrive backup (Parts 5, 6) |
| Stale memory in new session | Real-time writes + supersede-not-append + freshness gate (Part 5) |
| Conflicting memory picked arbitrarily | One fact one file + supersede + consolidate sweep (Part 5) |
| Promotion one-way and lossy | Keep both copies, extract and link, never move (Part 5) |
| Docs go stale | `@import` live files + generated docs + CI freshness check (Part 9) |
| Unauthorized across surfaces | Existing 1Password SA + hosted MCP connector everywhere (Part 4) |
| Depends on Mac being on | Hosted 1Password connector, not Mac-bound (Part 4) |
| "Must happen" only on Mac | Hooks on any Code machine + remote hooks + Cowork + skills for chat (Part 7) |
| Feels limited off the Mac | Always-complete fallback: native, remote MCP, or generated prompt (Part 7) |
| Don't know what a surface is missing | `surface-check` skill (Part 7.4) |
| Don't know how/when to merge | Merge-with-discretion skill does it and explains (Part 8.3) |
| Start on unmerged work | SessionStart gate addresses it first (Parts 5, 8) |
| Local and GitHub drift | Auto pull at start, auto push on commit (Part 0) |
| Long plan, can't start | Small grouped Parts + handoffs + PROGRESS.md (this file) |
| Want an agentic OS | Layer model + scheduler, orchestrator, control plane (Part 11) |

## Core principles

1. One source of truth, zero duplication. Others `@import` or path-reference, never paraphrase.
2. `@import` live files. Only small always-needed ones; large or occasional loads on demand.
3. Generate, do not hand-write, anything derivable.
4. Lean always-loaded layer (performance budget and staleness budget at once).
5. References, never secret values, in any tracked file.
6. Verify before asserting anything naming a file, function, flag, table, or tool.
7. Always-complete, never blocked. Composable, never restrictive. Defaults over constant choices.

## Architecture

One GitHub repo is a plugin marketplace and the single source of truth.

```
claude-kit/
  .claude-plugin/marketplace.json
  plugins/core/
    .claude-plugin/plugin.json
    skills/  commands/  agents/  hooks/hooks.json
    rules/
      global/                  # always-on, lean (loaded every session)
      modules/
        lang/                  # python, typescript, sql-server, power-query-m, env-vars, git, github-actions  (path-scoped)
        tool/                  # quickbase, appfolio, ...
        activity/              # etl-pipeline, policy-procedure, web-tool, data-modeling
        context/               # work, personal
      presets/                 # named module lists (work-etl-sql, personal-sports, policy-procedure, ...)
  surfaces/                    # one operating profile per surface
  templates/project-CLAUDE.md
  memory/  MEMORY.md           # global lane (thin index + per-fact files)
  handoffs/                    # dated, git-tracked
  PLAN.md  PROGRESS.md  decisions/
```

## The agentic OS model (what ties this together)

You have been describing a personal agentic OS. There is no single "agentic OS" product;
it is this layered pattern, built from primitives you already have. Naming the layers makes
the plan one mental model instead of many loops.

| OS layer | What it is | Where in this plan |
|---|---|---|
| Kernel (always-on) | Global rules, surface profiles, must-happen procedures | Parts 2, 7 |
| Memory / state | Two-tier memory, handoffs, cloud backup | Parts 5, 6 |
| IO / credentials | 1Password + MCP connectors, references not values | Part 4 |
| Processes | Hooks (deterministic) + skills (workflows) + agents (workers) | Parts 3, 7 |
| Scheduler / daemons | Autonomous routines on a schedule or event | Part 11 |
| Orchestrator | Routes a task to the right preset, agent, skill, model | Part 11 |
| Control plane | One status view of state across surfaces | Part 11 |

Parts 0-10 build the OS. Part 11 adds the three pieces that make it run itself.

## Rules: composable module gallery

**Four dimensions** (a project draws from any of them):
- **global/** always loaded, lean: knowledge-capture, naming-discipline (language-independent),
  verify-before-assert, secrets-as-references, anti-stale, speed-by-default.
- **modules/lang/** path-scoped so they never leak across languages (`paths:` frontmatter):
  python loads for `**/*.py`, typescript for `**/*.{ts,tsx,js,jsx}`, sql-server for `**/*.sql`, etc.
- **modules/tool/** loaded when the tool is in play (quickbase, appfolio).
- **modules/activity/** loaded for the kind of work (etl-pipeline, policy-procedure, web-tool, data-modeling).
- **modules/context/** the work-vs-personal defaults that genuinely differ.

**Composition:** a `/new-project` command applies a **preset** (one choice) then lets you add or
remove any module. It **symlinks** the chosen modules into the project's `.claude/rules/`
(single source in the repo, path-scoped loading, zero drift) and writes a thin project
`CLAUDE.md` that `@imports` the always-on selections. Claude flags a better-fitting module if
it detects one, but applies the preset by default so you are not choosing every time.

**Seed the gallery from your existing engineering notes (terse but complete):**

| Your note section | Lands in |
|---|---|
| Knowledge capture; naming discipline (language-independent); ISO dates | `global/knowledge-capture.md`, `global/naming-discipline.md` |
| Error handling (fail loud, no partial writes, log with context) | `modules/coding/error-handling.md` |
| Input validation at boundaries (pydantic, untrusted external data) | `modules/coding/input-validation.md` |
| Design defaults (YAGNI, KISS, DRY; do not unify sports prematurely) | `modules/coding/design-defaults.md` |
| Python PEP 8 table; underscores not hyphens | `modules/lang/python.md` (paths: `**/*.py`) |
| JS/TS table; camelCase, kebab files, PascalCase components | `modules/lang/typescript.md` (paths: `**/*.{ts,tsx,js,jsx}`) |
| SQL Server object naming + LOCKED plural table rules + special cases | `modules/lang/sql-server.md` (paths: `**/*.sql`) |
| Power Query M; env vars UPPER_SNAKE_CASE; git; GitHub Actions | `modules/lang/power-query-m.md`, `env-vars.md`, `git.md`, `github-actions.md` |
| "Why naming differs" | `modules/lang/_why-naming-differs.md` (reference, not loaded) |

Example presets: `work-etl-sql` (global + coding + python + sql-server + env-vars + git +
github-actions + activity/etl-pipeline + context/work); `personal-sports-etl` (same, context/
personal); `policy-procedure` (global + activity/policy-procedure + context/work); `web-tool`
(global + coding + typescript + activity/web-tool).

---

# Execution plan (small steps; one Part per sitting; handoff at each boundary)

After each step append one line to `PROGRESS.md`. Log decisions to `decisions/`.

## Part 0: Tracker, repo, and sync routine (start here, ~20 min)
- [x] 0.1 Create empty GitHub repo `claude-kit`; clone locally.
- [x] 0.2 Add `PLAN.md` (this file), empty `PROGRESS.md`, `decisions/`, `handoffs/`.
- [x] 0.3 Set up sync: SessionStart hook does `git pull --ff-only` (surface divergence before
      work); commits auto-push. Commit and push. (SessionStart `startup` hook in tracked
      `.claude/settings.json`, non-fatal pull; commit-time auto-push enforced by the
      keep-tracker-current rule. Hook fires next fresh session.)
- [x] 0.4 `git pull` on your other machines; confirm `PLAN.md` opens everywhere.
- Done when: the plan opens on any machine and edits sync without manual steps.
- Handoff: write `handoffs/000-setup.md`; next prompt: "Start Part 1 of claude-kit PLAN.md."

## Part 1: Inventory existing, freeze old kit, quiet the fleet (~45 min)
- [x] 1.1 Inventory what already exists (1Password SA and vault, Mac op_* tools, github/
      cloudflare/context7 connectors, op-wrap, gh biometric, existing repos). Record in
      `decisions/`. Only gaps get built later.
- [x] 1.2 Tag schnapp-kit `main` as `record-2026-06-03`; push the tag.
- [x] 1.3 Disable schnapp-kit in `~/.claude/settings.json`; neutralize the auto-enable guard.
- [x] 1.4 Cut 19 plugins to a small keep-set; disable the rest (reversible); log keep-set.
- [x] 1.5 Fresh session: confirm no double hooks, no auto-PR, no auto-merge. (Config verified:
      no hooks in user settings; enabled plugins = keep-set only (caveman, github, superpowers,
      plugin-dev, pyright-lsp, frontend-design); schnapp-kit + compound-engineering autopilot
      disabled. Only the intentional 0.3 sync hook + benign caveman/superpowers SessionStart
      hooks. No auto-PR/auto-merge. Live fresh-session confirmation at next startup.)
- Done when: runtime is quiet and you recognize what exists and what is kept.
- Handoff after this Part.

## Part 2: Global lane + surface profiles
- [x] 2.1 Write `rules/global/` (seed from your notes: knowledge-capture, naming-discipline,
      plus verify-before-assert, secrets-as-references, anti-stale, speed-by-default).
- [x] 2.2 Create `~/.claude/CLAUDE.md` that `@imports` the small global files; symlink
      `~/.claude/rules/global` to the repo (one source, no drift, syncs via Part 0).
      (Owner-approved DIRECT @import approach: `~/.claude/CLAUDE.md` @imports the 7 global rules
      straight from `~/code/claude-kit/plugins/core/rules/global/` — single source, syncs via the
      0.3 pull, no symlink. Symlink intentionally skipped: `~/.claude/rules/` is itself an
      auto-load level, so symlink + @import would double-load. All 7 import targets verified to
      exist. The `~/.claude/CLAUDE.md` content will be captured in the README install checklist
      (Part 9.5). Live cross-repo load is 2.4.)
- [x] 2.3 Write `surfaces/` profiles (Code-Mac, Code-worklaptop, Code-workdesktop, Cowork,
      claude.ai, iPhone): where credentials come from, which tools and connectors exist, the
      routine procedures to run.
- [ ] 2.4 Verify the global lane loads from another repo.
- Handoff after this Part.

## Part 3: Rule module gallery, presets, and composer
- [x] 3.1 Build `rules/modules/{lang,tool,activity,context}` and seed from your notes per the
      mapping table above; add `paths:` frontmatter to every lang module.
- [x] 3.2 Write `rules/presets/` lists (work-etl-sql, personal-sports-etl, policy-procedure,
      web-tool, quickbase).
- [x] 3.3 Build the `/new-project` composer: apply a preset, allow add/remove, symlink chosen
      modules into the project `.claude/rules/`, write a thin project `CLAUDE.md`.
- [ ] 3.4 Verify: Python rules do not load when editing a `.sql` file, and vice versa.
- Done when: a new project rule set is composed in one choice and never leaks across languages.
- Handoff after this Part.

## Part 4: Credentials everywhere (no Mac dependency)
- [x] 4.1 RECREATE the 1Password Service Account: the prior one was DELETED (see
      decisions/0001), so `op`/`gh` are down. Create a new SA, grant the vaults, and put the
      new token on every surface (`~/.zshrc`, `~/.zshenv`, GitHub Actions secret, others).
- [x] 4.2 Add a hosted 1Password MCP connector (service-account-backed); enable on every
      surface as the primary secret path. Keep the Mac op_* tools as backup.
      DONE (2026-06-05): `connectors/op-mcp/` Node streamable-HTTP MCP (read-only op_read/
      op_list_vaults/op_list_items/op_health, bearer auth) DEPLOYED on Render free tier at
      `https://op-mcp.onrender.com`. Fronted for claude.ai/iPhone by a Cloudflare MCP server
      portal (`https://mcp.schnapp.bet/mcp`, Managed OAuth + static-bearer "Custom headers" to
      origin) and registered as a claude.ai custom connector — `op_health` authenticates from
      claude.ai. Code/Cowork use the Render URL + bearer directly. Mac op_* tools = backup.
      Runbook: connectors/op-mcp/DEPLOY.md. (Render free cold-start ~50s; optional uptime ping.)
- [x] 4.3 Put credential references (the `op://` map) in `.env.template` / `credentials-map.md`;
      never values. (Created `credentials-map.md` [resolution-by-surface + `web-variables` system
      items + bootstrap/connector secrets] and root `.env.template` [op:// URIs, no values;
      verified `.env.template` tracked, `.env` ignored]. Field labels noted-not-guessed since they
      don't follow the category default in this vault.)
- [x] 4.4 Verify with the Mac powered off: resolve a secret from claude.ai via the connector.
      DONE (2026-06-05): `op_health` authenticated AND `op_read` resolved a real `op://` value from
      claude.ai through the portal — Render-hosted, so no Mac in the resolution path (Mac power is
      irrelevant). Hygiene note added to connectors/op-mcp/README.md: op_read transits the value into
      the surface transcript; use deliberately; prefer Mac op_run/op_inject for command execution.
- Done when: no surface returns unauthorized, Mac on or off. — MET. **Part 4 COMPLETE (4.1–4.4).**
- Handoff after this Part.

## Part 5: Memory: both lanes, cross-surface, never stale
- [x] 5.1 Set `autoMemoryDirectory` to a repo-tracked path so project memory commits and syncs;
      gitignore local scratch. (Set in tracked `.claude/settings.json` -> `~/code/claude-kit/memory`;
      scratch covered by `scratch/` + `*.local.md` in .gitignore. Harness picks it up after the
      per-machine trust dialog; cross-session sync proof is 5.6.)
- [x] 5.2 Adopt: one fact one file; supersede not append; every memory carries `source:` and
      `updated:`. (Documented in memory/README.md + global/anti-stale.md; demonstrated by the
      seed per-fact files.)
- [ ] 5.3 SessionStart freshness gate: skip or quarantine superseded or out-of-date memories;
      surface unmerged or unpushed work first.
- [ ] 5.4 Stop/SessionEnd hook writes fresh memory and a handoff deterministically.
- [~] 5.5 Dual-altitude promotion: write the project-specific instance in the project lane AND
      extract the reusable principle to `global/speed-by-default.md`, linked both ways (nothing
      moved, nothing lost). Seed with your perf examples (read-once, module-level cache,
      ThreadPoolExecutor, set-based SQL/CTE, bulk insert, `fast_executemany=True`).
      PARTIAL: global principle seeded (global/speed-by-default.md) + promotion mechanic
      documented (memory/README.md). A live project-lane instance lands with real perf work.
- [ ] 5.6 Verify: lesson in repo A appears in a fresh session in repo B; a changed fact
      supersedes the old one, not duplicated.
- Handoff after this Part.

## Part 6: Cloud backup + Obsidian mirror
- [x] 6.1 OneDrive folder `claude-archive/` already created. Point session, chat, handoff,
      and memory-snapshot backups at it. DONE: `plugins/core/scripts/backup-archive.sh` mirrors
      repo markdown (memory/handoffs/decisions/PLAN/PROGRESS) + archives Claude Code session
      transcripts into `claude-archive/` (chosen layout: claude-archive is its own Obsidian vault).
      Run + verified — 18 md + 5 transcripts + generated home note. Auto-run via Stop hook = Part 7/5.4.
- [~] 6.2 Point the local Obsidian vault at the synced OneDrive folder; fix the Obsidian
      connection. VAULT READY (folder + structure + home note). Owner GUI on MacBook (parked,
      iPhone now): open `claude-archive` as a vault in Obsidian, install the Local REST API
      community plugin (the missing piece — obsidian MCP has no backend, so it disconnects),
      generate its API key, wire it into the obsidian MCP config.
- [ ] 6.3 Verify a non-Mac session's backup appears in OneDrive and then Obsidian. Parked: needs
      the MacBook (Obsidian) + a second surface/machine running the backup; check OneDrive cloud sync.
- Handoff after this Part.

## Part 7: Cross-surface "must happen" enforcement
- [~] 7.1 Author the core procedures once (session-start state check, on-correction doc/memory
      update, end-of-session log). AUTHORED (canonical, single home = memory/README.md):
      freshness-gate (session-start) + end-of-session-write existed; on-correction-update now added.
      The git/unmerged half of the session-start state check lands with Part 8. Hook/skill wiring = 7.2/7.3.
- [ ] 7.2 Implement as hooks for Code on all machines; use `http`/`mcp_tool` hook types for
      remote action. Verify whether Cowork runs them.
- [ ] 7.3 Implement the same procedures as skills plus always-loaded instructions for chat and
      Cowork.
- [~] 7.4 Add `surface-check` skill: reports loaded vs missing on the current surface. AUTHORED:
      `plugins/core/skills/surface-check/SKILL.md` — identifies the surface, probes each capability
      (rules/memory/creds/connectors/hooks/skills/git) instead of assuming, reports a loaded-vs-missing
      table + the always-complete fallback per gap. Enable-per-surface (claude.ai/Cowork) is Part 10.
- [~] 7.5 On-correction auto-update: correcting a mistake triggers the doc/memory update so it
      is not repeated, on any surface. PROCEDURE AUTHORED (memory/README.md "On-correction update":
      routes preference→rule, fact→memory-supersede, doc→fix-in-same-change). Hook (Code) + skill
      (chat/Cowork) wiring pending with 7.2/7.3.
- Handoff after this Part.

## Part 8: Git hygiene (simple by default)
- [ ] 8.1 Default: work on `main`, commit and push every change, log decisions and learnings.
- [ ] 8.2 SessionStart gate addresses unmerged or unpushed work before new work.
- [ ] 8.3 Merge-with-discretion skill: only when a branch exists (created with your explicit
      approval), it judges the right time, merges for you, explains why.
- Handoff after this Part.

## Part 9: Anti-staleness wiring + project template
- [ ] 9.1 `@import` canonical files in core CLAUDE.md and the template; remove duplicated facts.
- [ ] 9.2 Adopt generators (gen-catalog, update-codemaps, update-docs); mark outputs generated.
- [ ] 9.3 CI freshness check: fail a push if a generated doc is out of date; flag docs whose
      source changed after `last-verified`.
- [ ] 9.4 Finalize `templates/project-CLAUDE.md` and the `/new-project` composer output.
- [ ] 9.5 Write the per-surface install checklist in `README.md`.
- Handoff after this Part.

## Part 10: Wire surfaces + final verification
- [ ] 10.1 Make `claude-kit` a marketplace; install in Code; connect the repo in Cowork; add
      core skills in claude.ai.
- [ ] 10.2 Run the full verification list.
- Done when: the same core works on Code, Cowork, and claude.ai.

---

## Part 11: Agentic OS layer (the self-running top)
Added after the core works, so it never blocks the foundation.
- [ ] 11.1 Scheduler / daemons via scheduled-tasks/cron: nightly memory consolidation,
      doc-freshness sweep, sync-and-unmerged check, infra/pipeline health. Safe routines run
      and notify; anything mutating data, money, or production asks first. Results to the repo.
- [ ] 11.2 Orchestrator: a `/do` dispatcher that takes a task, picks the preset/rules, the
      agent or skill, and the model tier (reuse model-route and the planner), then runs it.
- [ ] 11.3 Control plane: a `status` skill/dashboard showing per-surface state, stale items,
      unmerged or unpushed work, last backup, and connector health (builds on `surface-check`).
- Done when: routines run unattended, one command dispatches work correctly, one view shows
  whole-system state.
- Handoff after this Part.

---

## Final verification

1. Record intact; old kit recoverable from the tag.
2. Quiet runtime; small keep-set; no autopilot or double hooks.
3. Global lane loads in every repo and surface.
4. Cross-repo lesson: lesson in A appears in a fresh session in B.
5. No stale memory: changed fact supersedes; freshness gate skips superseded.
6. Composed rules: Python rules absent when editing SQL; preset applied in one choice.
7. Credentials resolve from claude.ai with the Mac off.
8. Backup: a non-Mac session's work reaches OneDrive and Obsidian.
9. Surface awareness: `surface-check` lists loaded vs missing correctly.
10. Sync: edit on one machine, it is present on another at next session start.
11. Git: a session with unmerged work addresses it first.
12. Anti-staleness: a stale generated doc fails CI; no fact duplicated across files.
13. No secrets: only `op://` references in tracked files, no values.
14. Agentic OS: a scheduled routine runs unattended and reports; `/do` dispatches a sample
    task to the right worker; `status` shows correct cross-surface state.

## Owner-only steps (need you)

- 4.1 BLOCKER: recreate the deleted 1Password SA and rotate the token on every surface
  (see decisions/0001). Until then `op`/`gh` stay down (git SSH + GitHub MCP still work).
- 0.1 Create an empty PRIVATE repo `SchnappAPI/claude-kit` so the local commits can push
  (I cannot create the repo: `gh` is down). Or rotate the SA first and I create it via `gh`.
- 6.1 Done: OneDrive `claude-archive/` exists.
- Approve any future branch before it is created.

## Open items to confirm during execution

- Final keep-set in Part 1 (proposed, you approve).
- Whether Cowork executes hooks (treat as no until verified in 7.2).
- Official vs community 1Password MCP connector in 4.2. RESOLVED: no general official
  1Password remote MCP exists (the only official one, May 2026, is purpose-built for OpenAI
  Codex). Self-hosted `connectors/op-mcp/` stays the path. See decisions/0004.
