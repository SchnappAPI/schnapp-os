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
- [x] 2.4 Verify the global lane loads from another repo.
      VERIFIED 2026-06-05 (live `claude -p` in a second repo `/tmp/ck-verify/repo-b`): the session quoted
      the owner's unique global rule verbatim — `` `galPerUnitPerDay` not `gpud` `` (naming-discipline.md) —
      with no file read, proving `~/.claude/CLAUDE.md`'s `@import`ed global lane loads in an unrelated
      (and untrusted) repo. User-scope config loads regardless of CWD/trust.
- Handoff after this Part.

## Part 3: Rule module gallery, presets, and composer
- [x] 3.1 Build `rules/modules/{lang,tool,activity,context}` and seed from your notes per the
      mapping table above; add `paths:` frontmatter to every lang module.
- [x] 3.2 Write `rules/presets/` lists (work-etl-sql, personal-sports-etl, policy-procedure,
      web-tool, quickbase).
- [x] 3.3 Build the `/new-project` composer: apply a preset, allow add/remove, symlink chosen
      modules into the project `.claude/rules/`, write a thin project `CLAUDE.md`.
- [x] 3.4 Verify: Python rules do not load when editing a `.sql` file, and vice versa.
      VERIFIED 2026-06-05 (live `claude -p` in composed repo-b, both directions): after reading `loader.py`,
      the session quoted python.md examples (`fetch_player_props()`) and reported `SQL-ABSENT`; after reading
      `query.sql`, it quoted sql-server.md's `_archive` vs `_backup` rule and reported `PYTHON-ABSENT`.
      Native `paths:` frontmatter scoping loads a module only for matching files — zero cross-language leak.
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
- [x] 5.3 SessionStart freshness gate: skip or quarantine superseded or out-of-date memories;
      surface unmerged or unpushed work first.
      HOOK AUTHORED (plugins/core/hooks/session-start-gate.sh): absorbs the 0.3 pull, surfaces
      unpushed/unmerged/dirty git + a memory supersede-orphan scan; standalone-tested green
      (exit 0, non-blocking). The memory *reasoning* stays the agent procedure (memory/README.md).
      WIRED into .claude/settings.json (owner-approved explicitly).
      LIVE-VERIFIED 2026-06-05: the `===== claude-kit SESSION-START GATE =====` block printed at a
      real fresh session startup (sync + git state + memory supersede-orphan scan). Gate firing also
      confirms the per-machine workspace-trust dialog is accepted (else hooks + 5.1 memory lane would
      silently no-op).
- [x] 5.4 Stop/SessionEnd hook writes fresh memory and a handoff deterministically.
      HOOK AUTHORED (plugins/core/hooks/session-end-backup.sh): runs backup-archive.sh + surfaces
      unpushed/uncommitted state so the agent's memory/handoff write + push is not skipped (the
      deterministic half; prose authoring stays the agent procedure). WIRED into .claude/settings.json
      (owner-approved). LIVE-VERIFIED 2026-06-05: the deterministic deliverable (backup-archive.sh)
      ran green this session — mirrored repo md + 7 transcripts to the OneDrive claude-archive vault.
      The SessionEnd *event* fires by the same harness wiring as the SessionStart gate observed firing
      this session (5.3) and the Stop push-gate (7.2) — same settings.json hook mechanism, trust dialog
      accepted; SessionEnd output cannot be observed mid-session by construction (no turn follows it).
- [~] 5.5 Dual-altitude promotion: write the project-specific instance in the project lane AND
      extract the reusable principle to `global/speed-by-default.md`, linked both ways (nothing
      moved, nothing lost). Seed with your perf examples (read-once, module-level cache,
      ThreadPoolExecutor, set-based SQL/CTE, bulk insert, `fast_executemany=True`).
      PARTIAL: global principle seeded (global/speed-by-default.md) + promotion mechanic
      documented (memory/README.md). A live project-lane instance lands with real perf work.
- [x] 5.6 Verify: lesson in repo A appears in a fresh session in repo B; a changed fact
      supersedes the old one, not duplicated.
      VERIFIED 2026-06-05 (live `claude -p` in second repo `/tmp/ck-verify/repo-b`): a fresh repo-b session
      loaded the real global memory lane (quoted the `keep-tracker-current` fact + a throwaway `VERIFY-ALPHA`
      token); after superseding the fact IN PLACE to `VERIFY-BETA`, a fresh repo-b session saw `VERIFY-BETA`
      and `OLD: NO` (no `ALPHA`), with exactly one fact file + one index line — supersede, not duplicate.
      DELIVERY (load-bearing, discovered here): cross-repo memory requires `autoMemoryDirectory` at USER
      scope. Plugins cannot set it (only `agent`/`subagentStatusLine`); project scope reaches only that
      project (a project-scope attempt in repo-b returned `LANE-ABSENT`). So `autoMemoryDirectory` was added
      to `~/.claude/settings.json` (owner-approved 2026-06-05) — the sibling of the user-global `~/.claude/
      CLAUDE.md` rules delivery. This is now a per-machine install step (README "Code — primary Mac" step 2).
      claude-kit's project-scoped entry remains a benign self-contained bootstrap fallback.
- Handoff after this Part.

## Part 6: Cloud backup + Obsidian mirror
- [x] 6.1 OneDrive folder `claude-archive/` already created. Point session, chat, handoff,
      and memory-snapshot backups at it. DONE: `plugins/core/scripts/backup-archive.sh` mirrors
      repo markdown (memory/handoffs/decisions/PLAN/PROGRESS) + archives Claude Code session
      transcripts into `claude-archive/` (chosen layout: claude-archive is its own Obsidian vault).
      Run + verified — 18 md + 5 transcripts + generated home note. Auto-run via Stop hook = Part 7/5.4.
- [x] 6.2 Make the Obsidian vault hold + serve the claude-archive across surfaces.
      DONE 2026-06-05: backup-archive.sh now DUAL-mirrors the knowledge md into the canonical vault
      (`$OBSIDIAN_VAULT_DIR/claude-archive/`, default `~/Documents/Obsidian`) in addition to OneDrive;
      obsidian-git pushes it to `SchnappAPI/obsidian-vault`. CORRECTION (earlier plan text was wrong): the
      obsidian MCP is the FILESYSTEM `obsidian-mcp` npm package (reads `~/Documents/Obsidian` directly) — NOT
      the Local REST API kind, so there is NO plugin to install/repair; it works on the Mac as-is. Off-Mac
      access = the new `connectors/obsidian-mcp/` remote MCP (built + locally verified; serves the vault from
      GitHub, no app dependency). Canonical vault = `~/Documents/Obsidian` (owner choice; `~/code/obsidian-vault`
      is a redundant clone to retire). PENDING (owner): rotate the leaked vault PAT + re-set obsidian-git auth
      in-GUI; deploy the remote MCP (owner-gated, connectors/obsidian-mcp/DEPLOY.md).
      UPDATE 2026-06-16: SUPERSEDED. Off-Mac obsidian is now served by a **Mac-hosted FastMCP server**
      (`~/obsidian-mcp/server.py`, port 8767, OAuth 2.1+PKCE+DCR) live at `https://obsidian-mcp.schnapp.bet/mcp`,
      connected + verified in claude.ai (7 tools). The Render `connectors/obsidian-mcp/` was never deployed and
      is now superseded (banner added; kept as the Mac-INDEPENDENT option). The vault moved to the canonical
      `~/Library/CloudStorage/OneDrive-Schnapp/Obsidian` (OneDrive-synced) with a back-compat symlink at
      `~/Documents/Obsidian`; brain agent + inbox watcher repointed. Authoritative detail: schnapp-bet
      `docs/CONNECTIONS.md` ("Obsidian MCP"/"Obsidian Brain Agent"). TRADE-OFF FLAGGED: the live server is
      Mac-hosted, so off-Mac access now needs the Mac on — a regression vs the locked "no Mac dependency"
      design that the superseded connector satisfied.
      UPDATE 2 (2026-06-16, decision A / decisions/0008): RESOLVED + single-sourced. The live server's
      source now lives in `connectors/obsidian-mcp/server.py`; the Mac runs it via symlink (plist
      unchanged); the Render/TS implementation was removed; obsidian-git push re-enabled so the
      GitHub-mirror fallback stays current. 6.2 met.
- [~] 6.3 Verify a non-Mac session's backup reaches OneDrive + the vault and is searchable off-Mac. Mechanism
      in place (dual-mirror + remote MCP built); full verify pends the remote-MCP deploy + a non-Mac run.
      UPDATE 2026-06-16: off-Mac *searchability* is LIVE (the Mac-hosted obsidian MCP is connected + verified
      in claude.ai). Caveat: Mac-hosted, so it needs the Mac on. The non-Mac *backup-write* half still pends
      (claude.ai is hookless; backup-archive.sh runs on the Mac).
- Handoff after this Part.

## Part 7: Cross-surface "must happen" enforcement
- [~] 7.1 Author the core procedures once (session-start state check, on-correction doc/memory
      update, end-of-session log). AUTHORED (canonical, single home = memory/README.md):
      freshness-gate (session-start) + end-of-session-write existed; on-correction-update now added.
      The git/unmerged half of the session-start state check lands with Part 8. Hook/skill wiring = 7.2/7.3.
- [~] 7.2 Implement as hooks for Code on all machines; use `http`/`mcp_tool` hook types for
      remote action. Verify whether Cowork runs them.
      AUTHORED in-repo (3 command hooks): session-start-gate.sh (=5.3), session-end-backup.sh (=5.4),
      and session-stop-push-gate.sh (Stop: blocks stopping while commits are unpushed; anti-loop via
      stop_hook_active + offline allowance; warns-not-blocks on uncommitted) — owner chose enforcement
      (Option 2: "never want pending changes"). All wired in plugins/core/hooks/hooks.json (portable
      plugin deployment, ${CLAUDE_PLUGIN_ROOT}; activates at Part-10 install). All tested standalone
      (gate/backup exit 0 non-blocking; stop-gate: clean→allow, unpushed→block JSON, retry→warn+allow).
      .claude/settings.json activation (all 3 hooks, ${CLAUDE_PROJECT_DIR} paths) APPLIED — explicit
      owner approval after the auto-mode classifier correctly blocked a premature self-wire (a
      clarifying question ≠ consent). Hooks load at session start, so live-verify is at the NEXT fresh
      session. Still open in 7.2: live-verify; remote http/mcp_tool hooks; Cowork-runs-hooks check.
      SCOPE GAP (flagged 2026-06-05): 7.2 says "hooks for Code on ALL machines", but the .claude/
      settings.json wiring fires ONLY when cwd IS the claude-kit repo — the gate + push-gate do NOT run
      in the owner's other repos yet. True global delivery is the PLUGIN (Part 10; ${CLAUDE_PLUGIN_ROOT}
      resolves anywhere) or absolute-path ~/.claude entries. The project-agnostic gate + push-gate
      (global behaviors) must be SPLIT from the claude-kit-specific backup at delivery, else they
      double-fire once the plugin is installed and the backup runs in every unrelated repo. RESOLVED in
      decisions/0005 (dictated by the locked single-source/no-siloing decisions, not an owner choice):
      the PLUGIN delivers the global gate+push-gate (${CLAUDE_PLUGIN_ROOT}, fires everywhere on Part-10
      install); claude-kit project settings keep ONLY the backup; at Part 10 the gate+push-gate are
      removed from project settings to avoid double-fire; ~/.claude absolute-path hooks rejected
      (machine-bound). Current claude-kit wiring = dev-time dogfood; 7.2 closes when Part 10 goes global.
- [~] 7.3 Implement the same procedures as skills plus always-loaded instructions for chat and
      Cowork.
      SKILL AUTHORED: plugins/core/skills/session-hygiene/SKILL.md — the three must-happen procedures
      (freshness gate / end-of-session write / on-correction update) for hookless surfaces, pointing to
      the canonical memory/README.md (no restatement) + the hookless execution notes (read git via the
      GitHub connector; persist via create_or_update_file or a generated Code prompt; backup caveat).
      Surface profiles (claude-ai-web, cowork, iphone) wired to name the skill. Always-loaded-instruction
      ENABLEMENT per surface (claude.ai project instructions / Cowork) + live test = Part 10 (like 7.4).
- [~] 7.4 Add `surface-check` skill: reports loaded vs missing on the current surface. AUTHORED:
      `plugins/core/skills/surface-check/SKILL.md` — identifies the surface, probes each capability
      (rules/memory/creds/connectors/hooks/skills/git) instead of assuming, reports a loaded-vs-missing
      table + the always-complete fallback per gap. Enable-per-surface (claude.ai/Cowork) is Part 10.
- [~] 7.5 On-correction auto-update: correcting a mistake triggers the doc/memory update so it
      is not repeated, on any surface. PROCEDURE AUTHORED (memory/README.md "On-correction update":
      routes preference→rule, fact→memory-supersede, doc→fix-in-same-change). COVERED: hookless
      surfaces via the session-hygiene skill (7.3); on Code it is the always-loaded procedure + global
      rules — "the owner corrected me" is semantic, so no deterministic command hook is the right
      mechanism (the Stop push-gate enforces only the push half). Live demo is organic on the next
      real correction.
- Handoff after this Part.

## Part 8: Git hygiene (simple by default)
- [x] 8.1 Default: work on `main`, commit and push every change, log decisions and learnings.
      ENCODED in plugins/core/rules/modules/lang/git.md "Workflow" (work on main; commit+push every
      change; branches only with explicit owner approval; address unmerged/unpushed first; log
      decisions/progress). Resolves git.md's prior dangling "see the project's git workflow" pointer.
      Enforcement already live (keep-tracker-current memory + anti-stale "pushed immediately" + the
      Part-7 gate/push-gate); demonstrably followed (every commit this build is push-immediately).
- [x] 8.2 SessionStart gate addresses unmerged or unpushed work before new work.
      IMPLEMENTED by session-start-gate.sh (=5.3): surfaces unmerged/unpushed/dirty git at start;
      the Stop push-gate adds turn-by-turn push enforcement. LIVE-VERIFIED 2026-06-05 with 5.3 — the
      SESSION-START GATE printed branch/clean/in-sync state at a real startup. The Stop push-gate is
      exercised by the very commit that flips these boxes (held unpushed for one turn to confirm the
      block); the observed result is recorded in PROGRESS.md.
- [~] 8.3 Merge-with-discretion skill: only when a branch exists (created with your explicit
      approval), it judges the right time, merges for you, explains why.
      SKILL AUTHORED: plugins/core/skills/merge-with-discretion/SKILL.md — precondition (a non-main
      branch exists + was approval-gated), readiness (tests/build/review/CI, evidence not vibes),
      timing discretion, then merge + explain; defers merge mechanics to git.md + the superpowers
      finishing-a-development-branch skill (no duplication). Unverifiable until a branch actually
      exists (default is work-on-main), so [~] not [x].
- Handoff after this Part.

## Part 9: Anti-staleness wiring + project template
- [x] 9.1 `@import` canonical files in core CLAUDE.md and the template; remove duplicated facts.
      DONE: (a) "core CLAUDE.md" = `~/.claude/CLAUDE.md` already `@import`s the 7 global rules straight
      from the repo (Part 2.2). (b) The template (`templates/project-CLAUDE.md`, 9.4) REFERENCES the
      canonical sources (global lane, gallery, generated CATALOG) and copies no rule content; it does
      NOT re-`@import` globals because they already load via `~/.claude/CLAUDE.md` (re-import =
      double-load, the same trap 2.2 settled). (c) Dedup sweep: no living doc paraphrases a rule body
      (distinctive global-rule lines appear only in their canonical rule); the only inventory is the
      generated CATALOG.md (nothing hand-listed elsewhere). Module/skill name-references in surfaces/
      template are intentional pointers, not duplicated facts.
- [x] 9.2 Adopt generators (gen-catalog, update-codemaps, update-docs); mark outputs generated.
      DONE: plugins/core/scripts/gen-catalog.sh generates plugins/core/CATALOG.md — an inventory of
      global rules, modules (by dimension, with paths/scope + reference-only split), presets (linked,
      not duplicated), skills, commands, hooks. Header marked "generated — do not edit"; output is
      deterministic (C-locale sort, no timestamps) so CI can diff it (9.3). "update-codemaps" does not
      apply (docs/config repo, no code graph; the only code is the self-contained op-mcp connector);
      "update-docs" = this generator today, extensible. Verified: runs green, byte-identical on re-run.
- [x] 9.3 CI freshness check: fail a push if a generated doc is out of date; flag docs whose
      source changed after `last-verified`.
      BUILT: .github/workflows/freshness.yml (GitHub-hosted ubuntu, Mac-independent; fetch-depth 0)
      runs plugins/core/scripts/check-freshness.sh, which does BOTH clauses: (1) regenerates
      CATALOG.md and fails if the committed copy is stale; (2) flags any doc whose `last-verified:`
      frontmatter predates a git change to a listed `sources:` path (no-op until adopted). Locally
      verified all 4 cases (clean→OK; dirty CATALOG→FAIL; stale last-verified fixture→FAIL; restored→OK).
      LIVE CI GREEN 2026-06-05 (run 27034142430, commit 62cc695). The gate PAID OFF on its first real
      runs: caught a cross-platform generator non-determinism (mawk vs BSD awk \x ellipsis escape) AND a
      real correctness bug — `secrets-as-references.md` (one of the 7 always-loaded global rules) was
      untracked because `.gitignore` `**/*secret*` matched it, so it loaded locally but was missing from
      GitHub/CI/cloned machines; both fixed before green.
- [x] 9.4 Finalize `templates/project-CLAUDE.md` and the `/new-project` composer output.
      DONE: created `templates/project-CLAUDE.md` — a thin, composed project CLAUDE.md (project
      name/purpose; "Rules in effect" = globals load via `~/.claude/CLAUDE.md` + composed modules load
      from `.claude/rules/` symlinks, path-scoped; project-lane section for purpose/schema/endpoints/
      perf/gotchas with dual-altitude link to speed-by-default; secrets as `op://` refs). `/new-project`
      step 4 now writes the CLAUDE.md FROM this template (single source for its shape) and the old
      "@import globals or note them" ambiguity is resolved to "note — do not re-import (double-load)".
      Path-scoped non-leak itself is verified in 3.4 (foundation-verify phase; mechanism now confirmed
      native — see the Finish sequence).
- [x] 9.5 Write the per-surface install checklist in `README.md`.
      DONE: README "Install (per surface)" section — Code (primary Mac + other machines), Cowork,
      claude.ai web, iPhone — with the four required items: (1) the `~/.claude/CLAUDE.md` content,
      single-sourced as tracked `templates/user-global-CLAUDE.md` and referenced (not duplicated as
      stale-prone prose); (2) the workspace-trust dialog step (gates hooks + the memory lane); (3) the
      OneDrive backup path; (4) the decisions/0005 plugin-vs-project hook-delivery split. Each surface
      references its surfaces/ profile + DEPLOY.md rather than restating them. Also updated the README
      Map (CATALOG + templates rows) and the "Staying current" CI line (now the live freshness gate).
- Handoff after this Part.

## Finish sequence (re-sequenced 2026-06-05; authoritative order for what is LEFT)
Foundation evaluated + verified sound: `.claude/rules/` auto-discovery + `paths:` frontmatter scoping is
NATIVE in current Claude Code (confirmed 2026-06-05; handoff 012), so the composition design holds — no
architectural rework. Gap found: the plan had NO phase for the PRODUCTIVE capability layer (owner's
flag: 0 domain skills/agents vs schnapp-kit's 134/39). Owner decisions (2026-06-05): DOMAIN-FIRST LEAN
capabilities; FINISH the agentic OS as the capstone. Part numbers are KEPT STABLE (Part 10 = wire/
package, Part 11 = agentic OS) so other docs (decisions/0005, surfaces, settings, hooks, memory) that
cite them stay valid — no renumber ripple. The Capability layer is inserted as its own phase BEFORE
Part 10. Remaining work, in dependency order — do earlier-listed first to avoid rework:

1. **Foundation verify (cheap confirmations) — DONE 2026-06-05.** 2.4 (global lane loads in another repo),
   3.4 (path-scoped non-leak), 5.6 (cross-repo memory + supersede) all live-confirmed via `claude -p` in a
   real second repo. 5.6 surfaced + closed the only delivery gap: `autoMemoryDirectory` must be user-scope
   (`~/.claude/settings.json`, owner-approved) — plugins cannot deliver it. Base is locked. Next: Capability layer.
2. **Capability layer (NEW phase, below):** select + build the domain-first gap set. BEFORE packaging, so
   the plugin ships the complete set and the final verify runs against it (no re-package/re-verify rework).
3. **Part 10 — Wire surfaces + package:** marketplace + plugin.json delivering the COMPLETE set; plugin
   delivers the global gate+push-gate, strip the dup from settings.json (0005); wire Cowork/claude.ai/
   iPhone + per-surface skill enablement (closes 7.3/7.4/7.5 enablement).
4. **Part 11 — Agentic OS capstone:** scheduler, `/do` orchestrator, `status` control plane.
5. **Final verification sweep:** the 14-point list against the complete system → production-ready sign-off.

Owner-gated parallel tracks (any time, non-blocking): 6.2/6.3 Obsidian — RESOLVED (decision A /
0008): Mac-hosted server single-sourced in `connectors/obsidian-mcp/`, Render retired, mirror push
re-enabled. Remaining: retire the redundant `~/code/obsidian-vault` clone (owner). 4.2 connector
redeploy (Render Manual Deploy + Cloudflare re-sync), the DB_Storage / appfolio-marketing-project
Actions-secret decision. 5.5 dual-altitude + 8.3 merge-skill close opportunistically (real perf work /
first approved branch).

## Capability layer (domain-first, lean, non-duplicative) — DO BEFORE Part 10
The productive teeth (the gap the owner flagged). Owner chose DOMAIN-FIRST LEAN: build ONLY what serves
the owner's actual platform AND is not already provided elsewhere (rebuilding what exists = the sprawl we
are escaping). Steps labeled C.x to keep Part numbers stable. Method:
- [x] C.0 Gap inventory FIRST (never build blind). For each candidate, check whether it already exists in
      INVENTORY RECORDED 2026-06-05 → decisions/0007-capability-inventory.md: all 253 schnapp-kit components
      (134 skills / 39 agents / 59 commands / 21 hooks) deduplicated into ~11 intent clusters with
      compose-vs-archive-vs-gap coverage tags. C.0 conclusion: the only genuine owner-domain gaps are
      `etl-pipeline-build`, `sql-server-patterns`, `/update-docs`(+`/update-codemaps`), a `sql-etl-reviewer`
      agent, and (conditionally) `tool/quickbase`+`tool/appfolio`. Everything else composes (keep-set /
      available skills / connectors / claude-kit) or archives. Stays [~] until the owner confirms the C.1 build set.
      (a) keep-set plugins (superpowers = TDD/debug/brainstorm/code-review/worktrees; caveman; plugin-dev;
      frontend-design), (b) available skills (anthropic-skills: pq-flat-map-type / fish-compare /
      sports-data-auditor / xlsx / pdf / docx; the `data:*` suite; `design:*`; deep-research), (c) MCP
      connectors (op-mcp; Mac ops MCP; GitHub; Cloudflare). EXISTS → COMPOSE/reference it (name it in the
      right preset + surface profile), do NOT rebuild. Only the genuine GAP is built. Record in decisions/.
- [x] C.1 Build the GAP capabilities (lean, into the gallery, each cataloged + preset-slotted). Owner's
      BUILT 2026-06-05: the 7 new GAP components (group 1) + the ~14 lean archive ports + docs-lookup (group 2),
      all cataloged (22 skills / 2 agents / 4 commands; freshness green). Preset-slotting = C.2.
      platform = Python ETL → SQL Server 2022 (scheduled via GitHub Actions/LaunchAgents); Power Query M
      prototyping; sports data (personal); web tools; Quickbase; AppFolio; policy/procedure docs. Candidate
      gap set (confirm against C.0 — build only what's missing):
        • skill `etl-pipeline-build` — Python ETL → SQL Server (idempotent, fast_executemany, op:// env,
          Actions schedule); composes etl-pipeline + sql-server + speed-by-default rules.
        • skill `sql-server-patterns` — T-SQL / SQL Server 2022 (owner uses SQL Server, NOT postgres/mysql;
          schnapp-kit's DB skills do not fit); composes the sql-server lang rule.
        • `tool/quickbase` + `tool/appfolio`: grow the rule stubs into skills ONLY if no env skill covers
          them (fish-compare already does AppFolio reconciliation → compose, don't rebuild).
        • command `/update-docs` (+ `/update-codemaps`): port lean from schnapp-kit for the owner's OTHER
          (ETL) repos, not claude-kit itself.
        • agents: build domain agents ONLY where the gap is real (Explore/Plan/general-purpose + caveman +
          superpowers cover generic reviewer/architect roles). Likely 0-2 (e.g. a SQL-ETL reviewer).
- [x] C.2 Presets: extend the domain bundles (e.g. work-etl-sql) to name the new skills so `/new-project`
      composes a real working set. Regenerate CATALOG (CI enforces freshness).
      DONE 2026-06-05: presets.md gained a "Recommended skills per preset" section (human + a machine-readable
      `skills:` map) naming the C.1 domain skills/agents AND the already-HAVE skills (pq-flat-map-type, data:*,
      sports-data-auditor/fish-compare/xlsx, deep-research, docs-lookup) + a cross-cutting list. Skills are
      plugin-global (not symlinked), so they are NAMED for relevance. Template gained a "Skills in reach" slot
      and /new-project step 4 now fills it from the preset's `skills:` list. CATALOG unchanged (presets/template
      aren't catalog content); freshness green.
- [x] C.3 schnapp-kit (`~/code/schnapp-kit`, frozen record) stays the ON-DEMAND archive — pull a
      capability only when a real task needs it; nothing bulk-migrated (anti-sprawl).
      DONE 2026-06-05 (standing policy, already recorded in decisions/0003): the C.1 build pulled ONLY the
      owner-locked checked set (decisions/0007) — ~14 lean ports of 253 archive components — and the whole
      session/memory cluster (~25 components) was deliberately NOT ported (claude-kit replaces it). schnapp-kit
      (tag record-2026-06-03) remains the recoverable archive; future pulls are task-driven, not bulk.
- Done when: a real ETL/SQL/Quickbase/AppFolio/policy task is served end-to-end by claude-kit's own
  composed set + referenced existing skills, nothing duplicated, gallery still understood.
- Handoff after this phase.

## Part 10: Wire surfaces + final verification
- [ ] 10.1 Package: `.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`
      (components auto-discover by directory — skills/commands/agents auto; hooks via hooks.json). Install
      in Code as a marketplace plugin so the PLUGIN delivers the global gate+push-gate everywhere
      (`${CLAUDE_PLUGIN_ROOT}`); then REMOVE those two from the project `.claude/settings.json` to avoid
      double-fire, keeping ONLY the backup (decisions/0005). Packages the COMPLETE Capability-layer set.
- [ ] 10.2 Wire the other surfaces: connect the repo in Cowork; add the core + domain skills and the
      op-mcp connector in claude.ai + iPhone; enable session-hygiene / surface-check per surface (closes
      the 7.3/7.4/7.5 per-surface enablement).
- [ ] 10.3 Run the full verification list (below) against the complete system.
- Done when: the same core + capabilities work on Code, Cowork, and claude.ai/iPhone.
- Handoff after this Part.

---

## Part 11: Agentic OS layer (the self-running top)
The capstone (owner: finish it now). Reuses schnapp-kit pieces on-demand (model-route, autonomous-loops).
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

- 4.1 RESOLVED (2026-06-16): the 1Password Service Account works — `op-wrap.sh` resolves the global
  + per-service `op://` refs and `op_run` resolved 23 refs this session; all three MCP connectors +
  Flask/web run off it. (A bare `op whoami` through the Mac MCP shell fails by design — that
  subprocess has its op identity stripped — which is NOT an outage.) The original blocker (deleted SA,
  decisions/0001) no longer applies. Verify `gh` separately if a workflow needs it.
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
