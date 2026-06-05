# 0007 — schnapp-kit capability inventory (C.0): one checkbox per item

Date: 2026-06-05. Status: inventory recorded; build/keep set pending owner confirm.

Source: `~/code/schnapp-kit` (frozen, tag `record-2026-06-03`). Total: **253 components**
(134 skills · 39 agents · 59 commands · 21 hooks). Every component is listed once, with its own
checkbox, so you can keep a single item out of any group.

---

## Read this first (it answers the whole thing)

- **Your new kit is `claude-kit`.** "Keep X" = X ends up in claude-kit. Not kept = X stays in the
  `schnapp-kit` archive folder on disk, which you can pull from any time later.
- **Check a box = "put this in claude-kit." Uncheck = "leave it in the archive."** One box per member.
- Each item has **one status** telling you what checking it would actually do:

| Status | What it means | If you check it |
|--------|---------------|-----------------|
| 🔴 **GAP** | You do NOT have this today, and it fits your work (Python ETL, SQL Server, Power Query, your repos). | I **build** it into claude-kit. |
| 🟢 **HAVE** | You **already have this in every session right now** — it comes from a plugin/skill/connector that's already on (named in parentheses). Nothing to build. | I **name it in a project preset** so composed projects list it explicitly. (Leaving it unchecked changes nothing — you still have it.) |
| ⚪ **SKIP** | Lives in the archive, outside your day-to-day work. | I **pull that one item** into claude-kit now. |

- **Your real decision is just the 🔴 GAP items.** The 🟢 HAVE items you already have (checking only adds a
  pointer in a preset). The ⚪ SKIP items you can ignore unless one catches your eye.
- Pre-checked `[x]` = my recommendation. Edit freely.

---

## 🔴 THE GAPS — your actual choices (build these into claude-kit?)

- [x] **etl-pipeline-build** (skill) — Python ETL → SQL Server: idempotent upserts, `fast_executemany`, `op://` secrets, GitHub Actions schedule.
- [x] **sql-server-patterns** (skill) — T-SQL / SQL Server 2022 idioms (your DB; the archive only has Postgres/MySQL, wrong dialect).
- [x] **/update-docs** (command) — regenerate docs from schemas/routes/scripts in your *other* ETL repos.
- [x] **/update-codemaps** (command) — token-lean architecture maps for those repos.
- [x] **sql-etl-reviewer** (agent) — a reviewer specialized in T-SQL + ETL correctness. *(Only if the generic reviewers feel too generic — otherwise skip.)*
- [x] **tool/quickbase** (skill) — Quickbase patterns. *(Build only when a real Quickbase task needs it; nothing else covers Quickbase.)*
- [x] **tool/appfolio** (skill) — AppFolio patterns. *(Probably skip: `fish-compare` already does AppFolio reconciliation.)*

Everything below is reference. You only HAVE to act on the seven lines above.

---

## Full inventory — every member, by cluster

Sorted within each cluster: 🔴 first, then 🟢, then ⚪. `(s)`=skill `(a)`=agent `(c)`=command `(h)`=hook.

### 1 · Kit authoring (build Claude-Code components)
- [ ] agent-development (s) — how to write agents — 🟢 HAVE (plugin-dev)
- [ ] command-development (s) — how to write slash commands — 🟢 HAVE (plugin-dev)
- [ ] hook-development (s) — how to write hooks — 🟢 HAVE (plugin-dev)
- [ ] hookify-rules (s) — hookify rule syntax — 🟢 HAVE (plugin-dev)
- [ ] skill-development (s) — how to write skills — 🟢 HAVE (plugin-dev / skill-creator)
- [ ] write-a-skill (s) — create a new skill — 🟢 HAVE (plugin-dev / skill-creator)
- [ ] skill-create (c) — mine git history into a skill — 🟢 HAVE (skill-creator)
- [ ] plugin-structure (s) — plugin layout — 🟢 HAVE (plugin-dev)
- [ ] plugin-settings (s) — plugin config files — 🟢 HAVE (plugin-dev)
- [ ] mcp-integration (s) — add MCP to a plugin — 🟢 HAVE (plugin-dev)
- [ ] mcp-server-patterns (s) — build an MCP server — 🟢 HAVE (mcp-builder skill)
- [ ] agent-creator (a) — generate an agent — 🟢 HAVE (plugin-dev:agent-creator)
- [ ] create-plugin (c) — guided plugin creation — 🟢 HAVE (plugin-dev:create-plugin)
- [ ] new-sdk-app (c) — scaffold an Agent SDK app — 🟢 HAVE (claude-api skill)
- [ ] skill-scout (s) — search before building a skill — 🟢 HAVE (find-skills skill)
- [ ] search-first (s) — research before coding — 🟢 HAVE (superpowers brainstorming)
- [ ] skill-stocktake (s) — audit skills for quality — ⚪ SKIP
- [ ] skill-comply (s) — check skills are actually followed — ⚪ SKIP
- [ ] skill-health (c) — skill portfolio dashboard — ⚪ SKIP
- [ ] harness-audit (c) — repo harness scorecard — ⚪ SKIP
- [ ] context-budget (s) — find context-window bloat — ⚪ SKIP
- [x] rules-distill (s) — extract rules from skills — ⚪ SKIP
- [ ] setup-matt-pocock-skills (s) — wire AGENTS.md skill block — ⚪ SKIP
- [ ] check-marketplace-drift (h) — warn on marketplace drift — ⚪ SKIP
- [ ] install-plugin (h) — plugin bootstrap — ⚪ SKIP

### 2 · Agent orchestration & autonomous loops  → this is your Part-11 capstone (reuse later, don't build now)
- [ ] agentic-os (s) — multi-agent OS on Claude Code — ⚪ SKIP → Part 11
- [ ] autonomous-agent-harness (s) — autonomous agent system — ⚪ SKIP → Part 11
- [ ] autonomous-loops (s) — loop architectures — ⚪ SKIP → Part 11
- [ ] continuous-agent-loop (s) — loops with quality gates — ⚪ SKIP → Part 11
- [ ] ralphinho-rfc-pipeline (s) — RFC-driven multi-agent DAG — ⚪ SKIP → Part 11
- [ ] blueprint (s) — one-line objective → build plan — ⚪ SKIP → Part 11
- [ ] plan-orchestrate (s) — plan → agent-chain prompts — ⚪ SKIP → Part 11
- [ ] dmux-workflows (s) — tmux multi-agent panes — ⚪ SKIP → Part 11
- [ ] claude-devfleet (s) — parallel agents in worktrees — ⚪ SKIP → Part 11
- [ ] parallel-execution-optimizer (s) — parallelize work — ⚪ SKIP (superpowers dispatching-parallel-agents)
- [ ] team-builder (s) — compose agent teams — ⚪ SKIP → Part 11
- [ ] santa-method (s) — dual-review convergence — ⚪ SKIP → Part 11
- [ ] agent-harness-construction (s) — design agent action spaces — ⚪ SKIP
- [ ] enterprise-agent-ops (s) — long-lived agent ops — ⚪ SKIP
- [ ] agentic-engineering (s) — eval-first agent engineering — ⚪ SKIP
- [ ] ai-first-engineering (s) — AI-heavy team model — ⚪ SKIP
- [ ] iterative-retrieval (s) — refine subagent context — ⚪ SKIP
- [ ] harness-optimizer (a) — tune the agent harness — ⚪ SKIP
- [ ] loop-operator (a) — run/monitor loops — ⚪ SKIP → Part 11
- [ ] ralph-loop / cancel-ralph / help (c) — Ralph loop control — ⚪ SKIP → Part 11
- [ ] santa-loop (c) — adversarial dual-review loop — ⚪ SKIP → Part 11
- [ ] loop-start / loop-status (c) — managed loop control — ⚪ SKIP → Part 11
- [ ] model-route (c) — pick model tier for a task — ⚪ SKIP → Part 11 (PLAN 11.2 reuses it)
- [ ] multi-plan / multi-execute / multi-frontend / multi-backend / multi-workflow (c) — multi-model dev flow — ⚪ SKIP → Part 11

### 3 · Planning, PRD & decisions
- [ ] plan (c) — restate + risk + step plan — 🟢 HAVE (superpowers writing-plans + Plan agent)
- [ ] prp-plan / prp-implement / prp-pr (c) — PRP plan/execute/PR — 🟢 HAVE (superpowers writing/executing-plans)
- [ ] plan-prd (c) — lean PRD → plan — 🟢 HAVE (superpowers)
- [ ] planner (a) — planning specialist — 🟢 HAVE (Plan agent)
- [ ] code-architect (a) — feature architecture blueprint — 🟢 HAVE (Plan agent)
- [ ] adr-writer (s) — author an ADR — 🟢 HAVE (claude-kit `decisions/` already does this)
- [ ] architecture-decision-records (s) — capture ADRs — 🟢 HAVE (claude-kit `decisions/`)
- [ ] adr (c) — create next ADR — 🟢 HAVE (claude-kit `decisions/`)
- [ ] protect-shipped-adrs (h) — block edits to shipped ADRs — ⚪ SKIP
- [ ] to-prd (s) — conversation → PRD on tracker — ⚪ SKIP (you have no PRD flow)
- [ ] prp-prd (c) — interactive PRD generator — ⚪ SKIP
- [ ] product-capability (s) — PRD → capability plan — ⚪ SKIP
- [ ] product-lens (s) — validate the "why" first — ⚪ SKIP
- [ ] to-issues (s) — plan → tracker issues — 🟢 HAVE (GitHub MCP)
- [ ] triage (s) — issue triage state machine — 🟢 HAVE (GitHub MCP)
- [x] grill-me (s) — stress-test your plan by interrogation — ⚪ SKIP *(pull if you want it)*
- [x] grill-with-docs (s) — grill + update docs inline — ⚪ SKIP *(pull if you want it)*
- [x] council (s) — four-voice decision council — ⚪ SKIP *(pull if you want it)*
- [ ] recursive-decision-ledger (s) — visible decision trail — ⚪ SKIP
- [ ] zoom-out (s) — higher-level perspective — ⚪ SKIP
- [ ] aside (c) — answer a side question, then resume — ⚪ SKIP

### 4 · Code review, quality, verification & debugging
- [x] **sql-etl-reviewer** — *(see GAP list — the only build candidate here)* — 🔴 GAP
- [ ] code-review (c) — review diff or PR — 🟢 HAVE (`/code-review` skill + superpowers review)
- [ ] review-pr (c) — multi-agent PR review — 🟢 HAVE (`/code-review`)
- [ ] code-reviewer (a) — quality/security review — 🟢 HAVE (superpowers + caveman reviewer)
- [ ] code-simplifier (a) — simplify recent code — 🟢 HAVE (`/simplify` skill)
- [ ] comment-analyzer (a) — comment-rot review — ⚪ SKIP
- [ ] silent-failure-hunter (a) — find swallowed errors — ⚪ SKIP
- [ ] type-design-analyzer (a) — type-design review — ⚪ SKIP
- [ ] pr-test-analyzer (a) — PR test-coverage review — ⚪ SKIP
- [ ] python-reviewer (a) + python-review (c) — Python review — ⚪ SKIP (generic review covers it)
- [ ] typescript-reviewer (a) — TS review — ⚪ SKIP
- [ ] django-reviewer (a) — Django review — ⚪ SKIP
- [ ] fastapi-reviewer (a) + fastapi-review (c) — FastAPI review — ⚪ SKIP
- [ ] database-reviewer (a) — Postgres review — ⚪ SKIP
- [ ] mle-reviewer (a) — ML eng review — ⚪ SKIP
- [ ] build-error-resolver / django-build-resolver / pytorch-build-resolver (a) + build-fix (c) — fix build errors — ⚪ SKIP
- [ ] tdd (s) / tdd-workflow (s) / tdd-guide (a) — test-first — 🟢 HAVE (superpowers test-driven-development)
- [ ] django-tdd (s) / python-testing (s) — language testing — ⚪ SKIP (superpowers TDD)
- [ ] e2e-testing (s) + e2e-runner (a) + browser-qa (s) — end-to-end UI tests — ⚪ SKIP
- [ ] verification-loop (s) / quality-gate (c) / checkpoint (c) — confirm done — 🟢 HAVE (superpowers verification + `/verify`)
- [ ] production-audit (s) / django-verification (s) / canary-watch (s) — prod-readiness checks — ⚪ SKIP
- [ ] gateguard (s) / safety-guard (s) — block risky ops until investigated — 🟢 HAVE (claude-kit Part-7 hooks)
- [ ] click-path-audit (s) — trace UI button state — ⚪ SKIP
- [ ] diagnose (s) — disciplined debug loop — 🟢 HAVE (superpowers systematic-debugging)
- [ ] agent-introspection-debugging (s) / agent-architecture-audit (s) — debug LLM agents — ⚪ SKIP
- [ ] eval-harness (s) / agent-eval (s) / ai-regression-testing (s) — LLM-app evals — ⚪ SKIP
- [ ] security-review (s) — security checklist — 🟢 HAVE (`/security-review` skill)
- [ ] security-scan (s+c) — scan .claude config (AgentShield) — ⚪ SKIP
- [ ] security-bounty-hunter (s) — find bounty bugs — ⚪ SKIP
- [ ] security-reviewer (a) — vuln detection — 🟢 HAVE (`/security-review`)
- [ ] secrets-hygiene-reviewer (a) — flag hardcoded secrets — 🟢 HAVE (claude-kit secrets-as-references rule)
- [ ] security_reminder_hook (h) — security reminder — 🟢 HAVE (claude-kit)
- [ ] coding-standards (s) — baseline conventions — 🟢 HAVE (claude-kit rules)

### 5 · Language & framework patterns
- [x] **sql-server-patterns** — *(see GAP list)* — 🔴 GAP
- [ ] python-patterns (s) / python-testing (s) — Python idioms — 🟢 HAVE (claude-kit python rule)
- [ ] postgres-patterns / mysql-patterns / prisma-patterns / redis-patterns / clickhouse-io / database-migrations (s) — other DB/ORM — ⚪ SKIP (wrong DB)
- [ ] django-patterns / django-celery / django-security / fastapi-patterns / nestjs-patterns / backend-patterns / hexagonal-architecture / api-design / api-connector-builder / error-handling (s) — backend frameworks — ⚪ SKIP (not your stack)
- [ ] frontend-patterns / frontend-a11y / accessibility / design-system / make-interfaces-feel-better / motion-foundations / motion-patterns / motion-advanced / motion-ui / ui-to-vue / frontend-design-direction (s) + a11y-architect (a) — frontend/UI/motion — 🟢 HAVE (frontend-design plugin + design:* skills)
- [ ] bun-runtime / nextjs-turbopack / nuxt4-patterns / vite-patterns (s) — runtimes/build tools — ⚪ SKIP
- [ ] pytorch-patterns / mle-workflow (s) + agent-sdk-verifier-py / agent-sdk-verifier-ts (a) — ML / SDK verify — ⚪ SKIP
- [x] regex-vs-llm-structured-text (s) — regex-vs-LLM parsing choice — ⚪ SKIP *(handy for ETL parsing; pull if wanted)*
- [ ] *Power Query M* — your reporting stack — 🟢 HAVE (pq-flat-map-type skill) — [x] name it in a preset

### 6 · Data, ETL & performance — your core domain
- [x] **etl-pipeline-build** — *(see GAP list)* — 🔴 GAP
- [x] data-throughput-accelerator (s) — speed up big ingestion/backfill/ETL — ⚪ SKIP *(the best archive ref to pull for ETL speed)*
- [x] latency-critical-systems (s) — low-latency systems — ⚪ SKIP
- [x] benchmark (s) / benchmark-optimization-loop (s) + performance-optimizer (a) — measure/optimize perf — ⚪ SKIP
- [x] content-hash-cache-pattern (s) — hash-keyed caching — ⚪ SKIP
- [x] cost-aware-llm-pipeline (s) — LLM cost routing — ⚪ SKIP
- [ ] *data analysis / dashboards / SQL authoring* — 🟢 HAVE (data:* skills: analyze, write-query, explore-data, build-dashboard) — [x] name in the ETL preset
- [ ] *spreadsheet / data audit* — 🟢 HAVE (sports-data-auditor, xlsx, fish-compare skills) — [x] name in your preset

### 7 · Research, docs & codebase comprehension
- [x] **/update-docs** + **/update-codemaps** — *(see GAP list)* — 🔴 GAP
- [x] doc-updater (a) / comment-analyzer (a) — doc/codemap agent — 🔴 part of the GAP build above
- [ ] deep-research (s) / exa-search (s) — multi-source research — 🟢 HAVE (deep-research skill) — [x] name in preset
- [ ] documentation-lookup (s) + docs-lookup (a) — current library docs — 🟢 HAVE (context7 MCP) — [x] name in preset 
- [ ] codebase-onboarding (s) / code-tour (s) + code-explorer (a) — understand a codebase — 🟢 HAVE (Explore agent)
- [ ] zoom-out (s) — broader context — ⚪ SKIP

### 8 · Session, memory & context — claude-kit already replaces ALL of this (recommend keep none)
> This whole cluster is the overlapping-memory sprawl you left schnapp-kit over. claude-kit's single memory
> lane + handoffs + Part-7 session hooks cover it. Nothing recommended.
- [ ] ck (s) — per-project memory — 🟢 HAVE (claude-kit memory lane)
- [ ] continuous-learning-v2 (s) — instinct learning via hooks — 🟢 HAVE (claude-kit memory + on-correction rule)
- [ ] handoff (s) — compact conversation → handoff — 🟢 HAVE (claude-kit handoffs/ + conversation-handoff skill)
- [ ] live-session-cache (s) — cache session turns to a branch — 🟢 HAVE (live-session-cache available skill)
- [ ] strategic-compact (s) — compact at logical points — 🟢 HAVE (chat-context skill)
- [ ] token-budget-advisor (s) — choose response depth — ⚪ SKIP
- [ ] save-session / resume-session / sessions (c) — session persistence — 🟢 HAVE (claude-kit handoffs + backup)
- [ ] learn / learn-eval / evolve (c) — mine session → skill/guidance — 🟢 HAVE (claude-kit knowledge-capture rule)
- [ ] instinct-export/import/status/promote/prune/projects (c) — instinct store ops — ⚪ SKIP
- [ ] session hooks: resume-breadcrumb / start-git-context / end-cleanup / stale-state-cleanup / pre-compact-snapshot / stop-reminder (h) — 🟢 HAVE (claude-kit Part-7 hooks)

### 9 · Git, GitHub & open-source
- [ ] git-workflow (s) — branching/commit conventions — 🟢 HAVE (claude-kit git rule)
- [ ] git-guardrails-claude-code (s) — block dangerous git — 🟢 HAVE (claude-kit push-gate hook)
- [ ] setup-pre-commit (s) — Husky/lint-staged hooks — ⚪ SKIP
- [ ] no-commit-to-main / auto-pr-after-commit / auto-merge-on-stop (h) — git automation — 🟢 HAVE (claude-kit deliberately rejects auto-pr/merge; works on main — decisions/0005)
- [x] clean-gone (c) — prune [gone] branches — ⚪ SKIP *(handy; pull if wanted)*
- [ ] github-ops (s) — issues/PR/CI via gh — 🟢 HAVE (GitHub MCP) — [ ] name in preset
- [ ] pr / prp-pr (c) — create a PR — 🟢 HAVE (GitHub MCP)
- [ ] opensource-pipeline (s) + opensource-forker / sanitizer / packager (a) — public-release chain — ⚪ SKIP

### 10 · Deploy, infra & monitoring
- [ ] deployment-patterns / docker-patterns (s) — deploy/containers — ⚪ SKIP
- [ ] pm2 (c) / setup-pm (c) — process/package manager setup — ⚪ SKIP
- [ ] workflow-env-validator (h) — validate workflow env — ⚪ SKIP
- [ ] dashboard-builder (s) — operator dashboards — 🟢 HAVE (data:build-dashboard) — [ ] name if wanted
- [ ] canary-watch (s) — post-deploy smoke checks — ⚪ SKIP
- [ ] enterprise-agent-ops (s) — agent observability — ⚪ SKIP

### 11 · Communication & token economy
- [ ] caveman (s) — terse output mode — 🟢 HAVE (caveman plugin, already on)
- [x] token-budget-advisor / context-budget / cost-aware-llm-pipeline / strategic-compact (s) — token/depth budgeting — ⚪ SKIP

---

## Summary
- **You must decide:** the 🔴 GAP list (7 lines at top; 4 pre-checked).
- **You already have:** every 🟢 HAVE item — checking one only adds a pointer in a project preset.
- **Recommend keep none of cluster 8** (memory) — claude-kit replaces it; that is the anti-sprawl win.
- Tell me your final 🔴 set (+ any 🟢/⚪ you want named/pulled) → C.1 builds only those → C.2 presets + CATALOG.
