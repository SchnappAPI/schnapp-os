# Schnapp-OS: Intent Capture (before cutting)

Date: 2026-06-23. Companion to [`docs/schnapp-os-research-and-decisions-2026-06-23.md`](schnapp-os-research-and-decisions-2026-06-23.md)
(§7.2 step 1: *capture intent before cutting*) and [`decisions/0011`](../decisions/0011-plan-review-ten-redecisions.md).

**Purpose.** Reconstruct what each layer / hook / skill / rule / connector was *meant* to do, separating
deliberate design from accretion, so the later **prune step does not delete something load-bearing.** This
records intent and current state. It does **not** prune — pruning is the last step in the order, after both
loops work. Prune/defer entries below are *candidates*, not actions.

**Method.** Five parallel read-only investigators, each grounding component intent in the `decisions/` ADRs and
`handoffs/` that hold the "why." Areas: hooks+scripts, skills+commands+agents, rules, connectors, memory+surfaces+meta.

---

## 1. The system as actually built, mapped to the two loops

The repo is a real, substantial agentic system: **26 skills, 5 commands, 2 agents, 26 rule files (7 global +
19 modules), 4 MCP connectors, 6 surface profiles, 6 scripts, 3 hooks, 11 decisions, 33 handoffs.** It is also,
structurally, **its own marketplace plugin** — `claude-kit-core@schnapp-os` with `source: "./plugins/core"`, so
`${CLAUDE_PLUGIN_ROOT}` resolves to the repo itself.

Mapped against the decision doc's reference architecture:

| Architecture layer | Built? | Where | Loop |
|---|---|---|---|
| Durable substrate (git repo) | ✅ sound | repo + GitHub origin | — |
| Kernel / policy (global rules) | ✅ sound | `rules/global/` (7), `@import`ed into `~/.claude/CLAUDE.md` | — |
| Memory tier (durable) | ✅ sound | `memory/` two-lane, `autoMemoryDirectory` | both |
| **Freshness loop** | ⚠️ **partial + buggy** | `session-start-gate.sh` (bare `git pull` fails); `session-hygiene`, `status`, `surface-check` | **freshness** |
| **Learning loop** | ❌ **mostly absent** | only distill (`rules-distill`), route (`session-hygiene`), retrieve (`docs-lookup`); **no capture, no promote/validate (eval gate)** | **learning** |
| Tool / MCP layer | ✅ built (Mac-bound) | 4 connectors; only op-mcp is Mac-independent | — |
| Credential resolution (#5) | ✅ op-mcp; ⚠️ per-surface still parallel | `connectors/op-mcp/` | — |
| Scheduler / orchestrator / control-plane | ⛔ deferred (#8) | `scheduled-tasks/`, `/do`, `status` | — |

**The two headline truths this confirms the doc's diagnosis on:**
- The **freshness loop exists but is broken** at its core sync (the bare `git pull --ff-only` that lost the
  decision doc) and its delivery is entangled with decision #2 (see §5).
- The **learning loop was never really built.** Capture is ad hoc (global rules + memory by hand); there is no
  capture hook, and no promote/validate eval gate. The user's next-after-freshness step (capture-and-route) is
  largely greenfield.

---

## 2. Load-bearing — must NOT be pruned

**Freshness loop:** `session-start-gate.sh` (the only deterministic freshness enforcement on Code),
`session-stop-push-gate.sh` (the owner-chosen hard "never leave work unpushed" guard), `status` skill
(whole-system reconciler), `surface-check` (per-surface freshness), `session-hygiene` skill (the hookless mirror
of both loops).

**Learning loop:** `memory/README.md` — the single authored home of all three loop procedures (freshness gate,
end-of-session write, on-correction routing) that the hooks and `session-hygiene` point at; the two-lane memory
design + per-fact files (the durable store); `MEMORY.md` index; `rules-distill` (distill→route); `docs-lookup`
(retrieve/validate).

**Kernel:** all **7 global rules** (working-style, knowledge-capture, naming-discipline, secrets-as-references,
verify-before-asserting, anti-stale, speed-by-default) — none is a stub or gallery machinery; they load every
session. Plus the real **rule content** inside the lang modules: `lang/sql-server.md` LOCKED plural-table rules
(highest value, owner-locked), `lang/python.md` PEP-8 table, `lang/typescript.md` naming, and the three
`coding/*` rules.

**Credentials / security (mid-flight, do not prune):** `connectors/op-mcp/` (the Mac-independent credential
tool, #5), the secrets trio (`vault-resolve`, `rotate-secret`, `cleanse-secrets`), `scan-secrets.sh` + its test,
`credentials-map.md`, and the credential/leak/op-wrap memory facts. Rotation is **incomplete** (owner-console
set + 28-file leak scrub still open) — these hold live remediation state.

**Owner-domain capabilities (real work):** `etl-pipeline-build`, `sql-server-patterns`, `quickbase`, `appfolio`,
`/update-docs`, `/update-codemaps`, `sql-etl-reviewer`, `performance-optimizer` (the seven 0007 GAP items + perf).

**Framing:** `surfaces/README.md` + `surfaces/code-mac.md` + the always-complete fallback model;
`templates/user-global-CLAUDE.md` (per-machine global-rule delivery).

---

## 3. Prune candidates (decide at the prune step, NOT now)

Ported from the old sprawling kit, serving no loop and no current owner task:

- **Token-economy trio:** `token-budget-advisor`, `context-budget`, `strategic-compact` — 0007 marked all three
  SKIP/HAVE-elsewhere (caveman, chat-context); ported anyway.
- **Generic perf/ML:** `content-hash-cache-pattern` (no caller), `cost-aware-llm-pipeline` (owner has no LLM
  batch pipeline), `benchmark` + `benchmark-optimization-loop` (overlap `performance-optimizer`).
- **Decision-aid trio:** `council`, `grill-me`, `grill-with-docs` — useful but overlapping; serve no loop.
- **Weak-tie:** `regex-vs-llm-structured-text`, `latency-critical-systems`, `data-throughput-accelerator` — keep
  only if a real current owner task references them.
- **Orphan script:** `scripts/check-op-refs.sh` — no caller in CI, hooks, or settings; never wired.
- **Rule stubs (empty):** `activity/policy-procedure.md`, `activity/web-tool.md`, `activity/data-modeling.md`,
  and the stub halves of `context/work.md`, `context/personal.md`; plus `lang/_reference-why-naming-differs.md`
  (never loaded as a rule).

## 4. Defer candidates (per decisions #8 and #3)

- **Agentic-OS layer (#8 — defer until both loops fire):** all of `scheduled-tasks/` (scheduler routines), the
  `/do` orchestrator, and the agentic-OS framing of `status`. *Exception:* `scheduled-tasks/doc-freshness-sweep.md`
  + `run-ci-routines.sh` directly serve the freshness loop and may be retained on that basis. `render.yaml` is
  NOT agentic-OS (it deploys op-mcp); keep.
- **Surfaces (#3 — narrow to what is real):** `code-mac.md` is the only confirmed primary. `code-work-machines.md`
  is an unfilled STUB (strongest prune). `iphone.md` (capture/trigger only) is thin. `claude-ai-web.md` +
  `cowork.md` are real-but-secondary. The remote-MCP architecture means narrowing any of these is reversible.
- **Module-gallery machinery (#4 — simpler rules):** `presets/presets.md`, the `/new-project` symlink composer,
  and the gallery structure of `templates/project-CLAUDE.md`. **Salvage** the real rule *content* (the lang/coding
  tables) and the "project lane" idea before dropping the wrapper. `paths:` frontmatter scoping is a **native
  Claude Code feature**, not gallery machinery — plain rules files keep per-language non-leak without the gallery.

---

## 5. Cross-cutting structural findings (these shape the build order)

1. **Decision #2 (drop plugin packaging) severs the freshness loop's delivery.** The global hooks (SessionStart
   gate + Stop push-gate) are delivered ONLY through the marketplace-plugin path (`hooks.json` via
   `${CLAUDE_PLUGIN_ROOT}`). The repo's `.claude/settings.json` wires only the SessionEnd backup. So flattening
   `plugins/core/` would **stop the freshness + push hooks from firing**, in every repo. Re-homing them (e.g. to
   `~/.claude/settings.json` absolute paths — previously rejected as machine-bound, now acceptable under a
   plainer/Mac-centric model) is a **prerequisite** of executing #2, and is freshness-loop work. The freshness
   step must own this.
2. **A stale gate copy is still firing.** This session's SessionStart printed `claude-kit SESSION-START GATE`,
   but the repo's current `session-start-gate.sh` says `schnapp-os`. A diverged installed copy is live. Reconcile
   in the freshness/guardrail step (verify which file actually fires; the bare-`git pull` fix must land on the
   live one).
3. **No scoped memory or control-plane MCP server exists (#6).** `op-mcp` = credential tool ✅; `obsidian-mcp` =
   de-facto memory/knowledge server (Mac-bound, OAuth); `github-mcp` = integration; `mac-mcp` = a 25-tool
   **mega-server** (ops + sports + credentials) — exactly the shape #6 says to avoid. #6's clean memory /
   control-plane split is not built. (#8 defers the control-plane, so this gap is intentional-for-now.)
4. **Mac-dependency.** 3 of 4 connectors require the Mac on (mac-mcp, github-mcp, obsidian-mcp). Only op-mcp is
   Mac-independent — the doc's "reachable with Mac off" goal is met only for credentials.
5. **The force-push PreToolUse guard (#9) does not exist yet.** No `--force` / `force-with-lease` reference
   anywhere. The old schnapp-kit `no-commit-to-main.sh` (now uninstalled) was the wrong guard. Build the real one
   in the guardrail step; it needs the same delivery decision as finding #1.
6. **Doc staleness queued by #2/#4.** Top-level `README.md` and `templates/project-CLAUDE.md` describe the
   marketplace-plugin packaging + `/new-project` gallery that #2/#4 retire — they read stale the moment those
   execute. Update in the same change.
7. **Known duplication (anti-stale debt):** `credentials-map.md` ↔ `memory/credentials-state.md` (two homes for
   rotation status; `credentials-map.md` `## Status (2026-06-17)` block is already stale vs the canonical memory
   fact); the `op://`-in-`.env.template` rule restated in `global/secrets-as-references.md` + `lang/env-vars.md`.
   Minor: 3 memory files lack `updated:`, so the freshness gate can't date them.

---

## 6. Owner action items surfaced (outside this repo)

- **Chat-memory feature (#10):** delete history + turn generation off in the Claude app (not a repo change).
- **Credential rotation (open legs):** owner-console set (GITHUB_PAT, Anthropic, Claude-OAuth, DB sa, Web App incl.
  RUNNER_API_KEY, Webshare, Cloudflare); 2 client bearer legs (claude.ai mac-mcp, Copilot github-mcp); `rm` the
  plaintext `…macmcp.plist.bak` (dead MAC bearer + live GH_PAT/RUNNER_API_KEY); 28-file obsidian-vault leak scrub.

---

## 7. What this means for the next steps

- **Freshness gate (next):** fix the bare `git pull` → explicit `ls-remote` compare + ff (near-instant budget);
  reconcile the stale `claude-kit` gate copy; decide hook re-homing (finding #1) since #2 will remove the plugin
  delivery; add the 1Password credential-store reconcile.
- **Learning loop capture-and-route (after):** this is the greenfield part — there is no capture hook and no
  promote/validate gate today. Build capture (Stop/SessionEnd enqueue) → distill (lean parse, LLM only for fuzzy)
  → route (correction→rule, fact→memory-supersede, procedure→skill) → validate before promote.
- **Prune (last):** execute §3/§4 against the as-built map, only once both loops fire. Subtract, don't complete.
