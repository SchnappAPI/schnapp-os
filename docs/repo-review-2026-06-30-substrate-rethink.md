# schnapp-os — substrate-rethink assessment (2026-06-30)

A point-in-time snapshot, like [`AUDIT.md`](../AUDIT.md) and [`repo-review-2026-06-29.md`](repo-review-2026-06-29.md).
For current status read the live sources: [PLAN.md](../PLAN.md) / [PROGRESS.md](../PROGRESS.md) (status),
[decisions/](../decisions/) (the why), [plugins/core/CATALOG.md](../plugins/core/CATALOG.md) (generated
inventory), [handoffs/](../handoffs/) (newest = resume point). This doc does not re-copy those.

**What this adds over its two predecessors.** [`AUDIT.md`](../AUDIT.md) (2026-06-25) is the exhaustive
72-check gap matrix; [`repo-review-2026-06-29.md`](repo-review-2026-06-29.md) is the orientation + gap-close
action plan. Both audit *gaps inside the existing design*. This doc takes the one lens neither did: **"given
primitives that did not exist when this was built — off-the-shelf MCP servers, the Claude Agent SDK, the
plugin marketplace — what should the substrate itself become?"** It is the output of a 5-agent parallel audit
(connectors / processes / automation / governance + a "what's-newly-possible" grounding pass) run 2026-06-30.

**Method note (owner interview).** Driver = all four (new primitives + cut maintenance + fix fragility +
health check). Appetite = replace a hand-rolled subsystem when an off-the-shelf primitive wins. Surfaces = all
used (Code on Macs, claude.ai web, iPhone, Cowork). Mac = always-on / server-like. These answers shaped the
verdicts: the portability layer is **load-bearing, keep it**; the rethink is about cutting per-piece
maintenance and closing silent-stop, not ripping out portability.

---

## Headline

**Surgical, not teardown.** The system is strong and mostly correct. Most hand-rolled pieces are unique and
earn their place; only a few have off-the-shelf replacements today. The new primitives hit exactly the two
weak axes named in [`framework.md`](framework.md): **Agent SDK → robust loops** (fixes *silent stop*) and
**off-the-shelf MCP → less hand-rolled code** (cuts maintenance). They do **not** touch the kernel (7 global
rules) or the portability layer (op-mcp + memory-mcp + portal) — those stay.

---

## What is actually newly possible (grounding, with corrections)

- **No official *Anthropic* GitHub MCP.** The in-session `mcp__e4f92151-…__github-mcp_*` tools are **the
  owner's own portal** (`mcp.schnapp.bet`) re-exposing the hand-rolled connectors (it also carries
  `mac-mcp_*`, `memory-mcp_*`, `op-mcp_*`) — not an off-the-shelf server. The real replacement for the
  hand-rolled GitHub bridge is **GitHub's own** `github/github-mcp-server` (GitHub-maintained; remote-hosted
  at `api.githubcopilot.com/mcp` or self-host; PAT or GitHub-App/OAuth). The reference `modelcontextprotocol/servers`
  repo has GitHub **archived**, so that is not the path.
- **Agent SDK + scheduled cloud agents is the canonical replacement for `claude -p` + LaunchAgent loops.**
  Corroborated by this session's own `schedule` skill + `mcp__scheduled-tasks__*` + `CronCreate` tools. It
  gives structured output, retries / bounded iteration, real error handling, and reuses the same
  skills/subagents/MCP config. Specific feature claims (vault-secret injection, memory stores, exact beta
  dates) are **verify-before-betting**, not asserted here.
- **Rules cannot be plugin-delivered.** Confirmed. So the `@import`-from-repo kernel is the *correct* pattern,
  not a gap. The marketplace play is for skills / agents / hooks / MCP only.
- **No off-the-shelf server speaks `op://`** (the only official 1Password remote MCP, May 2026, is
  OpenAI-Codex-specific — see [decisions/0004](../decisions/0004-off-mac-1password-connector.md)). op-mcp stays.

---

## REPLACE — the new-primitive swaps

| Swap | From (hand-rolled) | To (off-the-shelf) | Payoff | Decision (2026-06-30) |
|---|---|---|---|---|
| **Reflective loop** | `learning-worker.sh`: `claude -p --dangerously-skip-permissions` from a LaunchAgent — no retry/timeout, silent `exit 0` on missing claude | **Agent SDK** scheduled agent; keep `learning-gate.sh` as the gate | structured calls, retries, bounded iteration, heartbeat — biggest fragility win (3 of 5 agents flagged it) | **GREENLIT** (P3). De-risked first by the failure-alert added this session. |
| **GitHub bridge** | `github-mcp`: 43 tools, ~800 LOC, Mac-bound, own LaunchAgent + tunnel + portal slot | **GitHub official** `github-mcp-server` (remote or self-host) | deletes ~800 LOC + a service + tunnel + sleep-fragility; web/iPhone can connect it directly | **CONDITIONAL** on a parity proof — see gate below. Owner: no functionality loss. |
| **Obsidian** | `obsidian-mcp`: ~180 LOC hand-rolled OAuth 2.1/PKCE/DCR | **auth-only → bearer via portal** (ADR 0020 pattern). Keep all 7 tools incl. `inbox_drop`→brain-agent + `get_index` | deletes the hardest-to-debug code in the stack | **CONDITIONAL → auth-only is zero-loss** (see gate). The "community MCP for basic tools" variant is **dropped** (it would risk the brain-agent integration). |

**Parity gates (owner's "no functionality loss" condition):**
- **GitHub:** the hand-rolled 43 tools are all standard GitHub REST ops (no custom logic; one tool,
  `download_artifact`, is even dead — documented, never implemented). GitHub's official server is a
  **superset** (repos/issues/PRs/Actions/code-search/releases/orgs/notifications), and being remote-hosted it
  can be added **directly** as a claude.ai connector — which also *removes* a portal dependency. **Likely
  zero-loss, but not yet proven.** Pre-greenlight step: diff the official server's current tool list against
  the 43 in use, confirm hosting/auth fits the multi-surface need, run it alongside, then deregister. The
  "why it was built this way" reasons (full coverage + portal-fronting for web/iPhone) are both satisfied.
- **Obsidian:** the *reason* it is hand-rolled is `inbox_drop`→brain-agent FSEvents + `get_index` — no
  off-the-shelf server has these. **Therefore only the auth mechanism changes** (OAuth→bearer); every tool
  and integration stays. **Zero functionality loss.** Mac-bound either way (ADR 0008).

---

## KEEP — resist replacing (verified unique value)

- **op-mcp** — only off-Mac `op://` resolver; no off-the-shelf equal (4 tools, tiny). KEEP.
- **memory-mcp + the markdown substrate** — correct at ~11 facts. A DB/embeddings store adds cost + vendor
  lock + kills the git-diff audit trail, against the cost discipline. KEEP; just normalize the schema (below).
- **7 global rules + 7 hooks + the unique skills** (`status`, `surface-check`, `session-hygiene`, `council`,
  `grill-me`/`grill-with-docs`, `learn-route`, `rotate-secret`, `vault-resolve`, the domain skills) — **no
  marketplace equivalent.** KEEP.
- **infra-health probe (pure bash)** — must **NOT** become an LLM/SDK dependency (a watcher cannot depend on
  the thing it watches). KEEP as shell.
- **Portability chain** (SA token → op-mcp → portal → connectors) — load-bearing for the web surface
  (verified). The strongest piece of the system. KEEP.

---

## FIX — defects (fix-on-sight class) — DONE this session

| # | Sev | Where | Fix | Status |
|---|---|---|---|---|
| 1 | 🔴 sec | `connectors/mac-mcp/server.py:62` | hardcoded `runner-Lake4971` fallback → `""` (fail-closed; live op:// always injected). Code hygiene per secrets-as-references; the leak itself stays owner-accepted won't-do (2026-06-27), not reopened | **DONE** `62a837c` |
| 2 | 🟡 stale | `PLAN.md` final-verify #7 | `FAILING 2026-06-16` → `RESOLVED 2026-06-30` (ADR 0020 portal) | **DONE** `62a837c` |
| 3 | 🟡 stale | `memory/credentials-state.md` | "ROTATION STILL OWED" (contradicted its own risk-accepted banner) → "owner-accepted won't-do" | **DONE** `62a837c` |
| 4 | 🟡 schema | `memory/` 3 files | add missing `scope: global` (owner-working-preferences, op-wrap-token-unquoted, credential-leak-2026-06-17) | **DONE** `62a837c` |

---

## HARDEN — silent-stop (the weak axis) — DONE this session

| Item | What | Status |
|---|---|---|
| op-mcp + memory-mcp heartbeat | NEW `render-health.yml` cron (30 min, Mac-independent) pings both `/health`, opens/auto-closes a `[render-health]` issue on down, doubles as keep-warm. The only previously-unmonitored surface. | **DONE** `a5f0476` |
| learning-worker failure alert | `ops-alert.sh` RED on real failures / GREEN on healthy runs — closes the silent-swallow (a failed nightly run had no off-Mac signal). | **DONE** `a5f0476` |
| `com.schnapp.brain-watcher` | installed LaunchAgent, no repo file, not in `EXPECTED_AGENTS` = unauditable. Document + add to the probe, or retire. | **OPEN** (P1) |

---

## CUT — dedup / maintenance tax (P1, not yet done)

- **schnapp-os-core double-load:** 3 agents + several skills exist *both* as `plugins/core/` source *and* the
  installed `schnapp-os-core` marketplace plugin → load twice on the dev machine. Single-source it (repo
  dogfoods source; other machines consume the marketplace; do not load both).
- **Execute the deferred prune** ([`docs/intent-capture-2026-06-23.md §3`](intent-capture-2026-06-23.md);
  its "both loops fire" gate is now met): delete `surfaces/code-work-machines.md` (explicit STUB, zero usage),
  retire orphan `check-op-refs.sh` (warn-only), merge `context/personal`+`context/work` → one file, demote
  `lang/power-query-m` ("prototype only").
- **Normalize memory frontmatter to one schema + CI-enforce** (scope additions this session are the start;
  the canonical schema — flat README spec vs nested on-disk — needs an ADR before a full rewrite).

---

## Marketplace play

Repo = the plugin **source**. Publish `plugins/core/` → private marketplace as `schnapp-os-core` (partly
done). Consume via marketplace on non-dev machines; keep the **kernel as `@import`-from-repo** (rules can't be
plugin-delivered — correct, not a gap). Net action: fix the double-load so the dev machine doesn't load both.

---

## Sequenced plan

| Phase | Items | Status |
|---|---|---|
| **P0 — defects + cheap silent-stop closes** | security hygiene, 2 stale-status reconciles, 3 memory scope fields, render-health heartbeat, learning-worker failure alert | **DONE 2026-06-30** (`62a837c`, `a5f0476`) |
| **P1 — dedup / prune (low risk)** | execute the prune; merge context modules; resolve the schnapp-os-core double-load; CI-enforce memory schema; document/retire `brain-watcher` | open |
| **P2 — GitHub swap (staged)** | prove parity vs the 43 tools → run official alongside → deregister hand-rolled | open (gated on parity) |
| **P3 — loop swap + obsidian auth** | `learning-worker` → Agent SDK scheduled agent (after verifying SDK feature specifics); obsidian OAuth → bearer (zero-loss) | open (Loop greenlit) |
| **P4 — polish** | memory-mcp search scaling (only if the lane grows); `/do` vs `ce-work` reconcile (optional) | open |

---

## Don't regress (verified strengths)

Credential portability (one SA token resolves off-Mac, live-verified); cost discipline (every hosted piece on
a verified $0 tier, zero embeddings); single-source skills; the hard gates (force-push blocker,
secret-scan-on-write, stop-push-gate); the running read-only nightly cron (9+ green runs); the now-running
infra-health probe + mac-liveness dead-man's-switch + (new) render-health. The silent-stop gap was just being
closed — do not let it reopen.
