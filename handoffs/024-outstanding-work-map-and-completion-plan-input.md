# Handoff 024 — outstanding-work map (input for the owner's completion plan)

Date: 2026-06-16. Surface authored on: Claude Code (web remote container, repo cloned fresh; has a
local shell + git + the Mac/GitHub/obsidian/op/cloudflare MCP connectors). Status: PAUSED at owner
request to review and build an optimized completion plan.

PURPOSE: a single, self-contained map of everything still outstanding, grouped so the remaining
steps can be sequenced efficiently. Read handoff 023 first for the *how-we-got-here* context; THIS
file is the *what-is-left* and *who/where can do it*. Nothing here is new work — it is the audit of
remaining work plus a proposed efficient order.

NOTE on numbering: this took the next sequential handoff number (024). Handoff **025** is the
Part 11 build (same session, after this). The Mac-Code session that runs handoff 022 (plugin
install + hook de-dup) writes the next free number, **026**.

---

## 1. Verified current state (facts, re-checked this session)
- Freshness gate GREEN: working tree clean; branch `claude/claude-kit-session-plan-ygp2ad`
  == `origin/main` == its own remote (`git rev-list --left-right --count` = 0/0 both ways); no
  unpushed/unmerged work; no stale-memory supersede-orphans.
- Latest commit `d80f623` (handoff 023 staleness audit). Decisions 0001–0010 + handoffs 000–023
  continuous, no gaps.
- Deps PINNED (decisions 0008/0009): do NOT bump mcp/uvicorn/starlette/pydantic. mcp 1.27.2.
- All three custom MCP connectors live + healthy on the Mac (graceful-restart + REUSEADDR socket):
  github 8766, obsidian 8767, mac 8765. op-mcp hosted on Render + Cloudflare OAuth (mcp.schnapp.bet).
- Component counts: 22 skills / 2 agents / 4 commands (CATALOG freshness green).

## 2. The blocking insight (why sequencing matters)
Remaining work splits by WHICH SURFACE can execute it. That, not topic, is the efficient ordering axis:

- **A. Needs an interactive Claude Code session ON THE MAC** (Schnapps-MBP TUI):
  the `/plugin marketplace add`, `/plugin install`, workspace-trust dialog, `/hooks`, and Code
  restart cannot be driven from a shell or from the web container. → Part 10.1 / handoff 022.
- **B. Needs the OWNER acting in a client UI** (claude.ai web, iPhone app, Cowork):
  toggling connectors/skills, pasting always-loaded instructions, connecting the repo in Cowork.
  → Part 10.2. Depends on A being installed first.
- **C. Authorable + pushable from THIS surface** (web container / any Code session): writing
  skills, commands, scripts, docs into the repo. → Part 11, plus prep artifacts for A and B.
- **D. Owner-gated infra / one-approval items** that can happen any time, non-blocking.

A → B → (parts of) 10.3 is a hard chain. Part 11 (C) is independent of all of it.

---

## 3. Remaining work, itemized

### Part 10.1 — install the plugin + de-dup hooks  [SURFACE A — Mac Code]
- DONE (pushed): `.claude-plugin/marketplace.json`; `plugins/core/.claude-plugin/plugin.json`;
  `plugins/core/hooks/hooks.json` with SessionEnd stripped (plugin delivers ONLY SessionStart gate +
  Stop push-gate; backup stays project-scoped — decision 0005).
- PENDING (the whole exec): run the ready-to-run prompt in **handoff 022**. Steps: pull → `/plugin
  marketplace add ~/code/claude-kit` → `/plugin install claude-kit-core@claude-kit` → accept
  workspace-trust → verify via `/hooks` the gate+push-gate resolve under the plugin root → open a
  fresh session in an UNRELATED repo, confirm gate fires + backup does NOT → de-dup
  `~/code/claude-kit/.claude/settings.json` (remove SessionStart gate + Stop push-gate, keep ONLY
  SessionEnd backup + autoMemoryDirectory) → restart Code → confirm each hook fires exactly once,
  no double-fire/gap → run Final-verification items 2, 3, 11 → mark PLAN 7.2 + 10.1 done → write
  handoff 025, append PROGRESS, commit/push, session-hygiene wrap.
- CLOSES: PLAN 10.1 and 7.2 (the "hooks on all machines / true global delivery" scope gap).
- GOTCHA: order-coupled — install + confirm BEFORE removing project duplicates, else double-fire or
  coverage gap. Workspace-trust MUST be accepted or hooks + the memory lane are silently nullified.
- Also resolves the load-bearing 5.6 delivery note: cross-repo memory needs `autoMemoryDirectory`
  at USER scope (plugins can't set it) — confirm this is set on the Mac during install.

### Part 10.2 — wire the other surfaces  [SURFACE B — owner UI; depends on 10.1]
- DONE (pushed): `surfaces/always-loaded-instructions.md` (canonical hookless block) + per-surface
  "Enablement" checklists appended to `surfaces/{claude-ai-web,iphone,cowork}.md`.
- PENDING (owner action in each client):
  - claude.ai web + iPhone: enable core + domain skills and the op-mcp connector; paste
    `surfaces/always-loaded-instructions.md` into the claude.ai **Project custom instructions**.
  - Cowork: connect the `SchnappAPI/claude-kit` repo; paste the always-loaded block; enable
    session-hygiene / surface-check; verify whether Cowork runs hooks (open question — treat as no
    until verified).
- CLOSES: the per-surface enablement halves of 7.3 / 7.4 / 7.5, and 10.2.
- PREP I CAN DO FROM HERE (surface C, optional, unblocks B): assemble a single "paste-pack" — exact
  text + the per-surface toggle list — so the owner's UI actions are mechanical.

### Part 10.3 — final verification (14-point list)  [mixed; some items depend on 10.1]
The full list is in PLAN.md "Final verification". Status of each:
- Depends on 10.1 installed: #2 (no double hooks), #3 (global lane in every repo), #11 (unmerged
  work addressed first across repos), parts of #14.
- Runnable NOW from this surface (independent of 10.1): #12 anti-staleness (run
  `plugins/core/scripts/check-freshness.sh`; confirm no fact duplicated), #13 no-secrets (only
  `op://` refs in tracked files, no values), #9 surface-check (probe loaded-vs-missing), #1 record
  recoverable from tag, #5 supersede/no-stale memory.
- Already VERIFIED earlier (see PLAN): #4 cross-repo lesson (5.6, live), #5 supersede (5.6).
- Owner/Mac-dependent: #7 creds resolve with Mac off (op-mcp is hosted — testable), #8 non-Mac
  backup reaches OneDrive + Obsidian (6.3 — the backup-WRITE half still pends; off-Mac
  *searchability* is already live via the Mac-hosted obsidian MCP, caveat: needs Mac on), #10 sync.

### Part 11 — Agentic OS layer (capstone)  [SURFACE C — fully authorable here]
PLAN flags it "authorable now". No dependency on 10.1/10.2.
- 11.1 Scheduler/daemons (scheduled-tasks/cron via GitHub Actions and/or Mac LaunchAgents): nightly
  memory consolidation, doc-freshness sweep, sync-and-unmerged check, infra/pipeline health. Safe
  routines run + notify; anything mutating data/money/production asks first. Results to the repo.
- 11.2 `/do` orchestrator: dispatcher that takes a task, picks preset/rules + agent/skill + model
  tier (reuse model-route + the planner), then runs it.
- 11.3 `status` control plane: skill/dashboard of per-surface state, stale items, unmerged/unpushed
  work, last backup, connector health (builds on `surface-check`).
- Done when: routines run unattended, one command dispatches correctly, one view shows whole-system
  state. (Final-verification #14 closes here.)

### Smaller PARTIAL [~] items that close opportunistically (not blockers)
- 5.5 Dual-altitude promotion: global principle seeded (`rules/global/speed-by-default.md`) +
  mechanic documented. Pending: a live project-lane instance — lands with real perf work.
- 6.3 Non-Mac backup verify: off-Mac searchability LIVE; the non-Mac backup-WRITE half pends
  (claude.ai is hookless; backup-archive.sh runs on the Mac).
- 7.1 Core procedures authored (memory/README.md). The git/unmerged half landed with Part 8.
- 7.5 On-correction auto-update: procedure authored; covered on hookless surfaces via session-hygiene
  and on Code via always-loaded procedure + rules. Live demo is organic on the next real correction.
- 8.3 Merge-with-discretion skill authored; unverifiable until an approved branch actually exists.

## 4. Owner-gated / carryover items (any time, non-blocking — surface D)
- One approved `service_restart` call to runtime-verify the new graceful TERM path (self-verify +
  kickstart fallback branch). Code-verified + deployed but not yet exercised through the tool.
- Decide whether `flask_restart` should also go graceful (currently kickstart -k; Flask SIGTERM
  handling unverified; out of scope so far).
- GitHub Actions `OP_SERVICE_ACCOUNT_TOKEN` NOT yet scoped to `DB_Storage` +
  `appfolio-marketing-project` (master-token-spread concern; tracked open in both credential docs).
- Retire the redundant `~/code/obsidian-vault` clone (decision 0008 leftover).
- 4.2 connector redeploy (Render Manual Deploy + Cloudflare re-sync) — opportunistic.
- credentials-state.md (memory) vs credentials-map.md overlap — both current + consistent;
  consolidation is a refactor left to owner judgement.

## 5. Constraints / gotchas (do not relearn the hard way)
- Deps PINNED (0008/0009): never bump mcp/uvicorn/starlette/pydantic.
- Connectors are symlinked live on the Mac — EDIT REPO COPIES ONLY; restart to deploy.
- Restart `com.schnapp.macmcp` ONLY via a detached double-fork daemon (handoff 020/021) — it is the
  operating channel; a foreground restart severs the session. Never foreground.
- Persist writes via git (this surface) or the GitHub connector / a generated Code prompt
  (hookless surfaces). Never silently skip a write.
- Hook delivery split = decision 0005. Single-source/symlink rules = 0008/0009. Graceful restart =
  0010. Authoritative infra doc: schnapp-bet/docs/CONNECTIONS.md.
- Append-only HISTORY (handoffs, decisions, PROGRESS, memory logs) is never rewritten; only LIVE
  current-state docs get corrected.

## 6. Proposed efficient sequence (for the owner's plan — not yet executed)
Optimized to minimize surface-switching and respect the A→B chain while running C in parallel:

1. **Parallel track now (surface C, no owner needed):** author Part 11 in the web/Code container
   and push. Independent of everything else; biggest blockable-by-nothing win.
2. **One Mac-Code session (surface A):** run handoff 022 end-to-end (10.1 + 7.2). Single sitting;
   it is order-coupled so don't split it. Confirms `autoMemoryDirectory` user-scope too.
3. **One owner UI pass (surface B), after #2:** apply 10.2 across claude.ai + iPhone + Cowork using
   the paste-pack. Use the optional prep artifact below to make this mechanical.
4. **Final verification (10.3):** run the 10.1-independent items NOW (can fold into #1); run the
   hook-dependent ones (#2/#3/#11) at the end of the Mac-Code session in #2; close #14 when Part 11
   lands.
5. Sweep the surface-D carryover items opportunistically (one approved service_restart, etc.).

OPTIONAL low-cost prep I can produce from here before you plan, if you want them staged:
- (a) the 10.2 "paste-pack" (exact text + per-surface toggle list) — unblocks step 3.
- (b) the verbatim Mac-Code prompt/checklist for handoff 022 — unblocks step 2 (handoff 022 already
  has one; I can tighten it to a copy-paste runbook).
- (c) run the 10.1-independent 10.3 items now and record results.

## 7. Pointers
- Authoritative resume context: handoffs/023. This file: the remaining-work map.
- PLAN.md live checkboxes (open/partial): 5.5, 6.3, 7.1, 7.3, 7.4, 7.5, 8.3, 10.1, 10.2, 10.3,
  11.1, 11.2, 11.3.
- session-hygiene skill: plugins/core/skills/session-hygiene/SKILL.md (run at start + wrap).
- Decisions: decisions/0001–0010. Surfaces: surfaces/*.md. Memory: memory/*.md.
