# 0007 — schnapp-kit capability inventory (C.0): deduped, clustered, pick-ready

Date: 2026-06-05. Status: inventory recorded; C.1 build/keep set pending owner confirm.

Source: `~/code/schnapp-kit` (frozen, tag `record-2026-06-03`). Raw: **134 skills · 39 agents · 59 commands
· 21 hooks = 253 components**. Method (owner's referenced skills): inventory like `skill-stocktake`,
search-before-keep like `skill-scout`/`search-first`, cluster like `agent-sort`. Duplicates across
skill/agent/command/hook are collapsed into ONE capability row (members listed; nothing dropped).

---

## How to read this

**Coverage tag** — answers "do we already have this?" One per row:

| Tag | Meaning | Action implied |
|-----|---------|----------------|
| 🟢 `KEEP-SET` | An installed keep-set plugin already does it (superpowers / caveman / plugin-dev / frontend-design) | nothing — already on |
| 🔵 `SKILL` | An available skill already does it (anthropic-skills, `data:*`, `design:*`, deep-research) | nothing — already on |
| 🟣 `MCP` | An MCP connector does it (op-mcp / GitHub / context7 / Mac-ops / Cloudflare) | nothing — already on |
| 🟡 `CLAUDE-KIT` | claude-kit already built/designed it (memory lane, rule gallery, Part-7 hooks, surfaces, `decisions/`) | nothing — already on |
| 🔴 `BUILD` | Genuine gap in the owner's platform, nothing covers it | build lean in C.1 |
| ⚪ `PART-11` | Belongs to the agentic-OS capstone, not the capability layer | defer to Part 11 |
| ⚫ `ARCHIVE` | Outside the owner's platform | leave in schnapp-kit, pull on demand |

**Keep column** — what claude-kit should DO with it. This is the column to scan/edit:

| Mark | Meaning |
|------|---------|
| `★` | **BUILD** — create it in claude-kit (a real gap). |
| `◑` | **COMPOSE** — don't build, but explicitly name/wire the existing thing into a preset or surface profile so a composed project actually has it. |
| `·` | **leave** — auto-available everywhere already, or archived. No claude-kit action. |

---

## ⭐ PICK LIST (the quick way to choose — edit the checkboxes)

Pre-checked = my recommendation. Uncheck to drop, or add a note. Only `★`/`◑` rows appear here; everything
else is auto-available or archived (full detail in the cluster tables below).

### Build new — the genuine gap (`★`)
- [x] **`etl-pipeline-build`** (skill) — Python ETL → SQL Server 2022: idempotent upserts, `fast_executemany`, `op://` env, GitHub Actions schedule. Composes etl + sql-server + speed-by-default rules.
- [x] **`sql-server-patterns`** (skill) — T-SQL / SQL Server 2022 idioms (owner's DB; no archive skill fits).
- [x] **`/update-docs`** (command) — sync docs from source-of-truth (schemas, routes, scripts) in the owner's OTHER ETL repos.
- [x] **`/update-codemaps`** (command) — token-lean architecture codemaps for those repos.
- [ ] **`sql-etl-reviewer`** (agent) — domain code reviewer for T-SQL + ETL correctness. *(0–1 agent; only if generic reviewers feel too generic.)*
- [ ] **`tool/quickbase`** (skill) — grow the rule stub into a skill *only if* a real Quickbase task needs it (no available skill covers Quickbase).
- [ ] **`tool/appfolio`** (skill) — *probably NOT:* `fish-compare` available skill already does AppFolio reconciliation → compose instead.

### Compose existing — name it in a preset/surface so projects actually have it (`◑`)
- [x] **deep-research** (🔵 skill) — already available; name it in the research/ETL preset.
- [x] **context7 docs lookup** (🟣 MCP) — name it for library/API questions (replaces documentation-lookup/docs-lookup).
- [x] **`/code-review` + `/simplify` + superpowers review** (🟢) — name as the review path (replaces code-review/review-pr/reviewer agents).
- [x] **superpowers TDD + verification + debugging** (🟢) — name as the test/verify/diagnose path.
- [x] **`/security-review` + secrets-as-references rule** (🟢🟡) — name as the security path.
- [x] **fish-compare** (🔵 skill) — AppFolio reconciliation; name in the AppFolio/owner preset.
- [x] **pq-flat-map-type** (🔵 skill) — Power Query M (owner's stack); name in the work-etl preset.
- [x] **sports-data-auditor + xlsx/pdf/docx** (🔵 skill) — owner's data-audit + office formats; name where relevant.
- [x] **data:* suite** (🔵 skill — analyze / build-dashboard / write-query / explore-data) — name in the ETL/SQL preset (replaces dashboard-builder, sql ad-hoc).
- [x] **Mac-ops MCP + GitHub MCP** (🟣) — name in surface profiles (replaces github-ops/pm2/deploy ad-hoc + scheduling).
- [ ] **grill-me / council** (⚫→◑) — optional decision-pressure rituals; pull on demand only if wanted.

### Explicitly NOT kept (call-outs)
- ⚫ **Session/memory cluster (~25 components: ck, continuous-learning, handoff, live-session-cache, save/resume/sessions, instinct-\*)** — this is the overlapping-memory sprawl the owner LEFT. claude-kit's single memory lane + handoffs + Part-7 hooks already replace it. **Port nothing.**
- ⚪ **Loops + multi-agent (~28 components)** — that's the Part-11 capstone, reused on-demand. Not the capability layer.

---

## FULL DETAIL — 11 clusters

Legend recap: Keep `★`=build `◑`=compose `·`=leave · Tag = coverage above.

### 1 · Kit authoring (meta: build Claude-Code components)
> Verdict: plugin-dev keep-set covers authoring. claude-kit adds only its own gen-catalog/freshness. Nothing to build.

| Keep | Capability | What it does | schnapp-kit members | Tag |
|---|---|---|---|---|
| · | Component authoring | author skills/agents/commands/hooks/plugins/MCP | agent-development, command-development, hook-development, skill-development, write-a-skill, plugin-structure, plugin-settings, mcp-integration, mcp-server-patterns, hookify-rules, agent-creator(a), create-plugin(c), new-sdk-app(c), skill-create(c) | 🟢 KEEP-SET |
| · | Search before building | look for an existing skill first | skill-scout, search-first | 🟢/🟡 |
| · | Kit / token audit | audit skills, drift, context bloat | skill-stocktake, skill-health(c), skill-comply, harness-audit(c), context-budget, rules-distill, check-marketplace-drift(h), security-scan/AgentShield(s+c+a) | ⚫ ARCHIVE |

### 2 · Agent orchestration & autonomous loops
> Verdict: this IS Part 11 (the agentic-OS capstone). Reuse on-demand; not the capability layer.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| · | Autonomous loops | self-running agent loops with stop conditions | ralph-loop/cancel-ralph/help(c), santa-loop(c)+santa-method, continuous-agent-loop, autonomous-loops, autonomous-agent-harness, loop-start/loop-status(c)+loop-operator(a) | ⚪ PART-11 |
| · | Multi-agent / multi-model | dispatch parallel agents / route models | multi-plan/execute/frontend/backend/workflow(c), model-route(c), dmux-workflows, claude-devfleet, team-builder(s+c), parallel-execution-optimizer, plan-orchestrate, ralphinho-rfc-pipeline, blueprint, agentic-os | ⚪ PART-11 |
| · | Agent-harness engineering | design/optimize agent action spaces & ops | agent-harness-construction, harness-optimizer(a), enterprise-agent-ops, agentic-engineering, ai-first-engineering, iterative-retrieval | ⚫ ARCHIVE |

### 3 · Planning, PRD & decisions
> Verdict: compose superpowers planning + GitHub connector + claude-kit `decisions/`. Optional: grill-me/council on demand.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| · | Implementation planning | turn intent into a step plan | plan(c), prp-plan/prp-implement/prp-pr(c), plan-prd(c), planner(a), code-architect(a), blueprint | 🟢 KEEP-SET |
| · | PRD / product framing | PRD from intent; product diagnostics | to-prd, prp-prd(c), product-capability, product-lens | ⚫ ARCHIVE |
| · | Issues / triage | plan → tracker issues; triage flow | to-issues, triage | 🟣 MCP |
| · | ADR / decision records | record architectural decisions | adr-writer, architecture-decision-records, adr(c), protect-shipped-adrs(h) | 🟡 CLAUDE-KIT |
| ◑ | Decision-pressure rituals | stress-test a plan; structured disagreement | grill-me, grill-with-docs, council, recursive-decision-ledger, zoom-out, aside(c) | ⚫→◑ |

### 4 · Code review, quality, verification & debugging
> Verdict: compose keep-set/skills heavily. Only domain gap = a SQL/ETL reviewer (0–1 agent).

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| ◑ | Generic code review | review a diff/PR for quality | code-review(c)+review-pr(c), code-reviewer(a), code-simplifier(a), comment-analyzer(a), silent-failure-hunter(a), type-design-analyzer(a), pr-test-analyzer(a) | 🟢 KEEP-SET |
| ★? | Language-specific review | reviewer per language | python-reviewer(a)+python-review(c), typescript-reviewer(a), django-reviewer(a), fastapi-reviewer(a)+fastapi-review(c), database-reviewer(a), mle-reviewer(a) | 🔴 BUILD (SQL/ETL only) |
| · | Build-error resolvers | fix build/type errors | build-error-resolver(a), django-build-resolver(a), pytorch-build-resolver(a), build-fix(c) | ⚫ ARCHIVE |
| ◑ | TDD / testing | test-first; e2e | tdd, tdd-workflow, tdd-guide(a), django-tdd, python-testing, e2e-testing+e2e-runner(a), browser-qa | 🟢 KEEP-SET |
| ◑ | Verification / quality gates | confirm done; gate risky ops | verification-loop, quality-gate(c), checkpoint(c), production-audit, django-verification, canary-watch, gateguard, safety-guard, click-path-audit | 🟢/🟡 |
| · | Eval / benchmark (LLM apps) | eval-driven dev; agent evals | eval-harness, agent-eval, ai-regression-testing | ⚫ ARCHIVE |
| ◑ | Security review | scan for vulns / secrets | security-review, security-scan(s+c), security-bounty-hunter, security-reviewer(a), secrets-hygiene-reviewer(a), django-security, security_reminder_hook(h) | 🟢/🟡 |
| · | Hard-bug diagnosis | disciplined debug loop | diagnose, agent-introspection-debugging, agent-architecture-audit | 🟢 KEEP-SET |

### 5 · Language & framework patterns (path-scoped knowledge)
> Verdict: none is the owner's stack except SQL Server → archive the rest; build `sql-server-patterns`.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| ★ | SQL Server / T-SQL | owner's DB idioms | (none — closest are postgres/mysql, wrong dialect) | 🔴 BUILD |
| · | Other DB / ORM | postgres/mysql/etc patterns | postgres-patterns, mysql-patterns, prisma-patterns, redis-patterns, clickhouse-io, database-migrations | ⚫ ARCHIVE |
| · | Backend frameworks | Django/FastAPI/Nest/etc | django-patterns, django-celery, django-security, fastapi-patterns, nestjs-patterns, backend-patterns, hexagonal-architecture, api-design, api-connector-builder, error-handling | ⚫ ARCHIVE |
| · | Frontend / UI / motion | React/Next, a11y, motion | frontend-patterns, frontend-a11y, accessibility, design-system, make-interfaces-feel-better, motion-foundations/patterns/advanced/ui, ui-to-vue, frontend-design-direction, a11y-architect(a) | 🔵/🟢 |
| · | Runtimes / build tools | bun, turbopack, vite, nuxt | bun-runtime, nextjs-turbopack, nuxt4-patterns, vite-patterns | ⚫ ARCHIVE |
| · | Python (general) | PEP8 idioms, testing | python-patterns, python-testing | 🟡 CLAUDE-KIT |
| · | ML / model eng | PyTorch, MLE workflow | pytorch-patterns, mle-workflow, mle-reviewer(a), agent-sdk-verifier-py/ts(a) | ⚫ ARCHIVE |
| ◑ | Power Query M | owner's reporting stack | (none in schnapp-kit) — use **pq-flat-map-type** available skill | 🔵 SKILL |

### 6 · Data, ETL & performance — owner's core domain
> Verdict: closest to the owner. Build the ETL pipeline skill; pull data-throughput-accelerator on demand.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| ★ | ETL pipeline build | Python ETL → SQL Server, scheduled | (none — data-throughput-accelerator is the on-demand reference) | 🔴 BUILD |
| · | Throughput / latency / cache | speed up ingestion; low-latency | data-throughput-accelerator, latency-critical-systems, content-hash-cache-pattern, benchmark, benchmark-optimization-loop, performance-optimizer(a) | 🟡/⚫ |
| · | Cost / parsing heuristics | LLM cost routing; regex-vs-LLM | cost-aware-llm-pipeline, regex-vs-llm-structured-text | ⚫ ARCHIVE |
| ◑ | Data analysis / dashboards | query, profile, chart, dashboard | (use **data:* suite** available skills) | 🔵 SKILL |

### 7 · Research, docs & codebase comprehension
> Verdict: compose deep-research + context7; build `/update-docs`(+`/update-codemaps`) lean.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| ◑ | Deep web research | multi-source cited research | deep-research, exa-search, search-first | 🔵 SKILL |
| ◑ | Library/API docs lookup | current docs, not training data | documentation-lookup, docs-lookup(a) | 🟣 MCP |
| · | Codebase comprehension | onboard / tour / explore code | codebase-onboarding, code-tour, code-explorer(a), zoom-out | 🟢 KEEP-SET |
| ★ | Doc / codemap sync | regen docs & codemaps from source | update-docs(c), update-codemaps(c), doc-updater(a), comment-analyzer(a) | 🔴 BUILD |

### 8 · Session, memory & context — already replaced (port nothing)
> Verdict: this is the ~4 overlapping memory systems the owner FLED. claude-kit's memory lane + handoffs + Part-7 hooks replace ALL of it.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| · | Persistent project memory | auto-load context per project | ck, continuous-learning-v2 | 🟡 CLAUDE-KIT |
| · | Session save/resume/handoff | persist + resume sessions | handoff, live-session-cache, save-session/resume-session/sessions(c), session-* hooks (resume-breadcrumb, start-git-context, end-cleanup, pre-compact-snapshot, stop-reminder) | 🟡 CLAUDE-KIT |
| · | Learning / instincts | mine sessions into rules/skills | learn/learn-eval(c), evolve(c), instinct-export/import/status/promote/prune/projects(c) | 🟡 CLAUDE-KIT |
| · | Context compaction | compact at logical points | strategic-compact, iterative-retrieval | 🟢 KEEP-SET |

### 9 · Git, GitHub & open-source release
> Verdict: compose claude-kit git rule + GitHub connector. Archive the open-source chain.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| · | Git workflow + safety | branching, guardrails, pre-commit | git-workflow, git-guardrails-claude-code, setup-pre-commit, clean-gone(c), no-commit-to-main/auto-pr-after-commit/auto-merge-on-stop(h) | 🟡 CLAUDE-KIT |
| ◑ | GitHub ops / PR | issues, PRs, CI via gh | github-ops, pr/prp-pr(c), review-pr(c) | 🟣 MCP |
| · | Open-source release | fork, sanitize, package public | opensource-pipeline + forker/sanitizer/packager(a) | ⚫ ARCHIVE |

### 10 · Deploy, infra & monitoring
> Verdict: archive generic deploy; compose Mac-ops MCP + data:build-dashboard if needed.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| · | Deploy / containers | CI/CD, Docker, PM2 | deployment-patterns, docker-patterns, pm2(c), setup-pm(c), workflow-env-validator(h) | ⚫ ARCHIVE |
| ◑ | Dashboards / monitoring | operator dashboards; canary | dashboard-builder, canary-watch, enterprise-agent-ops | 🔵 SKILL |

### 11 · Communication & token economy
> Verdict: caveman keep-set already on; rest archive.

| Keep | Capability | What it does | members | Tag |
|---|---|---|---|---|
| · | Caveman compression | terse output mode | caveman | 🟢 KEEP-SET |
| · | Token / depth budgeting | choose response depth/cost | token-budget-advisor, context-budget, cost-aware-llm-pipeline, strategic-compact | ⚫ ARCHIVE |

---

## Counts (deduped dispositions)
- 🔴 **BUILD (gap):** 4 firm (`etl-pipeline-build`, `sql-server-patterns`, `/update-docs`, `/update-codemaps`) + 1–3 conditional (`sql-etl-reviewer`, `tool/quickbase`, `tool/appfolio`).
- ◑ **COMPOSE (name in a preset/surface):** ~12 existing capabilities (deep-research, context7, code-review/TDD/security paths, fish-compare, pq-flat-map-type, data:*/xlsx/pdf/docx, GitHub/Mac-ops MCP, optional grill-me).
- ⚪ **PART-11:** loops + multi-agent (~28 components).
- ⚫ **ARCHIVE:** the rest (~180 components) — pull on demand (C.3).

Next: owner confirms the BUILD set + any COMPOSE picks above → C.1 builds only those → C.2 presets + CATALOG.
