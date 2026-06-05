# 0007 — schnapp-kit capability inventory (C.0), deduplicated + clustered

Date: 2026-06-05. Status: inventory recorded; gap call (C.1 build set) pending owner confirm.

Source: `~/code/schnapp-kit` (frozen, tag `record-2026-06-03`). Raw counts: **134 skills, 39 agents,
59 commands, 21 hooks = 253 components**. Method (per the owner's referenced skills): inventory like
`skill-stocktake` Phase 1, search-before-keep like `skill-scout`/`search-first`, cluster like `agent-sort`.
Every component below is mapped to exactly one cluster; duplicates are collapsed to a single capability with
its members listed (nothing dropped). Granularity: ~11 top-level clusters, nested where a cluster is large.

Coverage tags (the C.0 compose-not-rebuild lens):
`KEEP` = covered by an installed keep-set plugin (superpowers / caveman / plugin-dev / frontend-design).
`AVAIL` = covered by an available skill (anthropic-skills, `data:*`, `design:*`, deep-research).
`CONN` = covered by an MCP connector (op-mcp, GitHub, context7, Mac-ops, Cloudflare).
`CK` = already built/designed in claude-kit (memory lane, rule gallery, Part-7 hooks, surfaces).
`GAP?` = owner-domain candidate, not covered → consider building in C.1.
`ARCHIVE` = outside the owner's platform → leave in schnapp-kit, pull on demand (C.3).

---

## 1. Kit authoring (meta — build Claude-Code components) — mostly `KEEP` (plugin-dev)
- **Component authoring** `KEEP`: agent-development + agent-creator(agent); command-development;
  hook-development + hookify-rules; skill-development + write-a-skill + skill-create(cmd); plugin-structure;
  plugin-settings; mcp-integration + mcp-server-patterns. → plugin-dev keep-set covers all of these.
- **Skill search-before-build** `KEEP`/`CK`: skill-scout ≈ search-first (researcher). Principle is C.0 itself.
- **Skill/kit audit** `GAP?`(light): skill-stocktake, skill-health(cmd), skill-comply, harness-audit(cmd),
  context-budget, check-marketplace-drift(hook), rules-distill, security-scan(AgentShield, skill+cmd+agent).
  Mostly meta-ops on a big kit; claude-kit's CATALOG+freshness CI already covers inventory/drift. Archive most.
- **Scaffolds** `KEEP`/`ARCHIVE`: create-plugin(cmd), new-sdk-app(cmd), setup-matt-pocock-skills, install-plugin(hook).
- Members: ~22. Verdict: **compose plugin-dev; do NOT rebuild.** claude-kit adds only its own gen-catalog/freshness.

## 2. Agent orchestration & autonomous loops (the "agentic OS") — `GAP?` → **Part 11**, not C.1
- **Autonomous loops**: ralph-loop/cancel-ralph/help(cmd), santa-loop+santa-method, continuous-agent-loop,
  autonomous-loops, autonomous-agent-harness, loop-start/loop-status(cmd)+loop-operator(agent), continuous-learning-v2.
- **Multi-agent / multi-model**: multi-plan/execute/frontend/backend/workflow(cmd), model-route(cmd),
  dmux-workflows, claude-devfleet, team-builder(skill+cmd), parallel-execution-optimizer, plan-orchestrate,
  ralphinho-rfc-pipeline, blueprint, iterative-retrieval, agentic-os.
- **Agent harness engineering**: agent-harness-construction, harness-optimizer(agent), enterprise-agent-ops,
  agentic-engineering, ai-first-engineering.
- Members: ~28. Verdict: **this is Part 11 territory, reused on-demand** (model-route, autonomous-loops named in
  PLAN 11). NOT a C.1 build. Native Claude Code crons/Workflow + superpowers dispatching cover much of it now.

## 3. Planning, PRD & decision rituals — partly `KEEP`/`AVAIL`, light `GAP?`
- **Implementation planning** `KEEP`: plan(cmd), prp-plan, plan-prd, prp-implement, prp-pr, planner(agent),
  code-architect(agent), blueprint. → superpowers writing-plans/brainstorming + native Plan agent cover this.
- **PRD / product** `AVAIL?`: to-prd, prp-prd, product-capability, product-lens. (ECC-specific; owner has no PRD flow.)
- **Issues / triage** `CONN`: to-issues, triage, setup-matt-pocock-skills. → GitHub connector + owner's trackers.
- **ADR / decisions** `CK`: adr-writer ≈ architecture-decision-records ≈ adr(cmd) + protect-shipped-adrs(hook).
  → claude-kit already uses `decisions/` ADRs (this very file). Compose the convention, not the skill.
- **Decision rituals**: council, grill-me, grill-with-docs, recursive-decision-ledger, zoom-out, aside.
- Members: ~22. Verdict: **compose keep-set/connectors + claude-kit's `decisions/`.** Maybe keep `grill-me` on-demand.

## 4. Code review, quality & verification — heavy `KEEP`/`AVAIL`; one owner `GAP?`
- **Generic review** `KEEP`/`AVAIL`: code-review(cmd)+review-pr, code-reviewer(agent), code-simplifier(agent),
  comment-analyzer, silent-failure-hunter, type-design-analyzer, pr-test-analyzer. → superpowers
  requesting/receiving-code-review + caveman:cavecrew-reviewer + the `/code-review`,`/simplify` skills.
- **Language reviewers** `ARCHIVE` except SQL/Python: python-reviewer+python-review(cmd), typescript-reviewer,
  django-reviewer, fastapi-reviewer+fastapi-review(cmd), database-reviewer, mle-reviewer. → only a **SQL/ETL
  reviewer** maps to the owner (PLAN C.1's "0–2 domain agents"). `GAP?` = `sql-etl-reviewer` agent (decide C.1).
- **Build-error resolvers** `ARCHIVE`: build-error-resolver, django-build-resolver, pytorch-build-resolver, build-fix(cmd).
- **TDD / testing** `KEEP`: tdd ≈ tdd-workflow ≈ tdd-guide(agent), django-tdd, python-testing, e2e-testing+e2e-runner.
  → superpowers test-driven-development.
- **Verification / gates** `KEEP`/`CK`: verification-loop, quality-gate(cmd), checkpoint(cmd), production-audit,
  django-verification, canary-watch, gateguard, safety-guard, click-path-audit. → superpowers
  verification-before-completion + the `verify`/`run` skills; gateguard/safety-guard overlap claude-kit hooks.
- **Eval / benchmark** `ARCHIVE`/`AVAIL`: eval-harness, agent-eval, ai-regression-testing, benchmark,
  benchmark-optimization-loop. (LLM-app evals; not the owner's ETL platform.)
- **Security** `KEEP`/`CK`: security-review, security-scan, security-bounty-hunter, security-reviewer(agent),
  secrets-hygiene-reviewer(agent), django-security, security_reminder_hook. → `/security-review` skill +
  secrets-as-references global rule. secrets-hygiene-reviewer overlaps the owner's secrets rule (compose).
- Members: ~45. Verdict: **compose keep-set/skills heavily; the only domain gap is `sql-etl-reviewer` (C.1, 0–1 agent).**

## 5. Language & framework patterns (path-scoped knowledge) — almost all `ARCHIVE`
- **Backend frameworks** `ARCHIVE`: django-patterns, django-celery, fastapi-patterns, nestjs-patterns,
  backend-patterns, hexagonal-architecture, api-design, api-connector-builder, error-handling. (Not owner's stack.)
- **Databases / ORM** `ARCHIVE` except SQL: postgres-patterns, mysql-patterns, prisma-patterns, redis-patterns,
  clickhouse-io, database-migrations. → owner uses **SQL Server 2022**, none of these fit → `GAP?` `sql-server-patterns`.
- **Frontend / UI / motion** `AVAIL`/`KEEP`: frontend-patterns, frontend-a11y, accessibility, design-system,
  make-interfaces-feel-better, motion-foundations/patterns/advanced/ui, ui-to-vue, frontend-design-direction,
  a11y-architect(agent). → frontend-design keep-set + `design:*` available skills.
- **Runtimes / build tools** `ARCHIVE`: bun-runtime, nextjs-turbopack, nuxt4-patterns, vite-patterns.
- **Python (general)** `CK`: python-patterns, python-testing. → claude-kit's python lang rule + superpowers TDD.
- **ML** `ARCHIVE`: pytorch-patterns, mle-workflow, mle-reviewer(agent), agent-sdk-verifier-py/ts(agents).
- Members: ~30. Verdict: **archive the non-stack frameworks; the owner gap is `sql-server-patterns` (C.1).**

## 6. Data, ETL & performance — the **owner's core domain**, `GAP?`
- data-throughput-accelerator, latency-critical-systems, benchmark/benchmark-optimization-loop,
  content-hash-cache-pattern, cost-aware-llm-pipeline, regex-vs-llm-structured-text, performance-optimizer(agent).
- Members: ~7. Verdict: **closest to the owner's platform.** None is a Python-ETL→SQL-Server pipeline skill →
  `GAP?` = **`etl-pipeline-build`** (compose etl-pipeline + sql-server + speed-by-default rules). data-throughput-
  accelerator is the on-demand reference to pull from (C.3). speed principle already in claude-kit's speed-by-default.

## 7. Research, docs & codebase comprehension — `AVAIL`/`CONN`; owner `GAP?` on doc-sync
- **Research** `AVAIL`: deep-research ≈ exa-search ≈ search-first. → deep-research available skill + exa/firecrawl.
- **Docs lookup** `CONN`: documentation-lookup + docs-lookup(agent). → context7 MCP (connected).
- **Codebase comprehension** `KEEP`: codebase-onboarding, code-tour, code-explorer(agent), zoom-out. → Explore agent.
- **Doc / codemap sync** `GAP?`: update-docs(cmd), update-codemaps(cmd), doc-updater(agent), comment-analyzer.
  → PLAN C.1 names `/update-docs`(+`/update-codemaps`) for the owner's OTHER ETL repos. Build lean.
- Members: ~12. Verdict: **compose deep-research + context7; build `/update-docs`(+`/update-codemaps`) lean (C.1).**

## 8. Session, memory & context — `CK` (already replaced; do NOT port — anti-sprawl)
- ck, continuous-learning-v2, handoff, live-session-cache, strategic-compact, context-budget,
  token-budget-advisor, iterative-retrieval; commands save-session/resume-session/sessions, learn/learn-eval,
  evolve/instinct-export/import/status/promote/prune/projects; hooks session-resume-breadcrumb/
  session-start-git-context/session-end-cleanup/stale-state-cleanup/pre-compact-snapshot/stop-reminder.
- Members: ~25. Verdict: **this is the ~4 overlapping memory systems the owner FLED.** claude-kit's single
  memory lane + handoffs + Part-7 hooks REPLACE all of it. **Port nothing.** (handoff/live-session-cache exist as
  available skills if ever needed.) Highest anti-sprawl value in the whole inventory.

## 9. Git, GitHub & release / open-source — `CK`/`CONN`; `ARCHIVE` open-source
- **Git workflow / safety** `CK`: git-workflow, git-guardrails-claude-code, setup-pre-commit; hooks
  no-commit-to-main/auto-pr-after-commit/auto-merge-on-stop/clean-gone(cmd). → claude-kit git.md rule + Part-7
  push-gate. (auto-pr/auto-merge deliberately NOT adopted — owner works on main, decisions/0005.)
- **GitHub ops / PR** `CONN`: github-ops, pr+prp-pr(cmd), review-pr(cmd). → GitHub MCP connector.
- **Open-source release** `ARCHIVE`: opensource-pipeline + forker/sanitizer/packager(agents). (One-off; pull on demand.)
- Members: ~12. Verdict: **compose git rule + GitHub connector; archive the open-source chain.**

## 10. Deploy, infra & monitoring — `ARCHIVE`/`CONN`
- deployment-patterns, docker-patterns, dashboard-builder, canary-watch, enterprise-agent-ops; pm2(cmd),
  setup-pm(cmd); workflow-env-validator(hook). → owner's infra is on the Mac-ops MCP + GitHub Actions; these
  generic deploy skills are out of domain. `dashboard-builder` overlaps `data:build-dashboard` (AVAIL).
- Members: ~7. Verdict: **archive; compose Mac-ops connector + `data:build-dashboard` if a dashboard is needed.**

## 11. Communication & token economy — `KEEP`
- caveman(skill+plugin) `KEEP`; token-budget-advisor, context-budget, cost-aware-llm-pipeline, strategic-compact.
- Members: ~5. Verdict: **caveman keep-set already installed; rest archive.**

---

## C.0 conclusion — the genuine owner-domain GAP (everything else composes or archives)
After dedup + coverage tagging, the build candidates that survive (owner's platform AND uncovered) are only:
1. **`etl-pipeline-build`** skill — Python ETL → SQL Server 2022 (idempotent, `fast_executemany`, `op://` env,
   GitHub Actions schedule). Composes etl-pipeline + sql-server + speed-by-default rules. (cluster 6)
2. **`sql-server-patterns`** skill — T-SQL / SQL Server 2022 (owner's DB; no archive skill fits). (cluster 5)
3. **`/update-docs`** (+ **`/update-codemaps`**) commands — lean, for the owner's OTHER ETL repos. (cluster 7)
4. **`sql-etl-reviewer`** agent — 0–1 domain reviewer (the only language-reviewer that maps). (cluster 4)
5. **`tool/quickbase` + `tool/appfolio`** — grow the existing rule stubs into skills ONLY if no available skill
   covers them (fish-compare already does AppFolio reconciliation → compose, don't rebuild). (decide in C.1)

Everything in clusters 1,2(→Part 11),3,8,9(open-source),10,11 = compose existing or archive. Session/memory
(cluster 8) is explicitly NOT ported (it is the sprawl the owner left). Inventory feeds C.1 (build only 1–5
above, owner-confirmed) → C.2 (presets + CATALOG) → C.3 (schnapp-kit = on-demand archive).
