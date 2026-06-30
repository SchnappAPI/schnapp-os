# schnapp-os — repo review, orientation map, and optimization plan (2026-06-29)

A point-in-time snapshot (like `AUDIT.md` and the `handoffs/`), not a live-maintained canonical doc.
For current status read the live sources it points at: [PLAN.md](../PLAN.md) / [PROGRESS.md](../PROGRESS.md)
(status), [AUDIT.md](../AUDIT.md) (the full 72-check gap matrix), [decisions/](../decisions/) (the why),
[plugins/core/CATALOG.md](../plugins/core/CATALOG.md) (generated component inventory),
[handoffs/](../handoffs/) (the newest is the resume point). This doc does not re-copy those; it orients
and prioritizes. Mutable counts here may drift — trust the generated catalog over this file.

Relationship to `AUDIT.md`: AUDIT is the exhaustive per-requirement gap analysis (2026-06-26). This doc
adds three things AUDIT does not: (1) an **orientation map** / inventory, (2) **reconciliation with what
changed since** AUDIT plus the **operational risks** surfaced in handoff 038, and (3) one **consolidated,
sequenced action plan**. For gap detail, follow the AUDIT references rather than expecting it restated here.

---

## Part 1 — Orientation map (what this is, what each layer does)

`schnapp-os` is not application code. It is a **personal multi-surface Claude operating system**: one
private git repo that is the single source of truth for how Claude behaves, remembers, and acts, kept
identical across Code (every Mac), Cowork, claude.ai web, and iPhone. Promise: one source, no duplication,
nothing siloed, nothing stale, secrets as references (never values), never blocked on any surface.

The mental model is OS layers (from PLAN.md). Use it as the map:

| Layer | What it is | Where it lives |
|---|---|---|
| **Kernel** (always-on) | 7 global rules + surface profiles + must-happen procedures | `plugins/core/rules/global/`, `surfaces/` |
| **Memory / state** | Two-lane (global/project) memory, handoffs, cloud backup | `memory/`, `handoffs/`, OneDrive mirror |
| **IO / credentials** | 1Password + MCP connectors; references not values | `connectors/`, `credentials-map.md`, `.env.template` |
| **Processes** | Hooks (deterministic) + skills (workflows) + agents (workers) | `plugins/core/{hooks,skills,agents,commands}/` |
| **Scheduler / daemons** | Autonomous routines on schedule/event | `scheduled-tasks/`, `.github/workflows/`, Mac LaunchAgents |
| **Orchestrator + control plane** | Route a task to the right worker; one status view | `do` skill, `status` skill |

`docs/framework.md` names the system's two enemies: **silent drift** and **silent stop**. Hold that lens:
it is the single best predictor of what is solid here versus what is fragile (see Part 2).

### Inventory by layer (and what each part is for)

- **Spine / governance** — `PLAN.md` (11-Part master plan, demoted to a parking lot by ADR 0011),
  `PROGRESS.md` (append-only log), `AUDIT.md` (self-grade: 72 checks, 20 present / 37 partial / 15 absent),
  `docs/framework.md` (durable why), `README.md` (the map, carries no status), `decisions/` (18 ADRs),
  `handoffs/` (39 dated session logs).
- **Kernel: rules** (`plugins/core/rules/`) — 7 **global, always-on** (working-style, knowledge-capture,
  naming-discipline, secrets-as-references, verify-before-asserting, anti-stale, speed-by-default), loaded
  into every repo via each Mac's `~/.claude/CLAUDE.md` `@import`. Plus on-demand modules under
  `lang/ tool/ activity/ coding/ context/`. The gallery/preset/composer was removed (ADR 0011 #4).
- **Processes** (`plugins/core/`) — hooks (6 active, wired in repo `.claude/settings.json`; `hooks.json`
  intentionally empty per ADR 0011 #2), ~23 skills, 4 commands, 3 agents, ~12 helper scripts + tests.
- **IO: connectors** (`connectors/`) — five MCP servers. **op-mcp** (off-Mac secret resolver, cloud/Render)
  and **memory-mcp** (memory lane via GitHub API, cloud/Render) work with the Mac asleep. **mac-mcp**
  (shell/SQL/files/services bridge), **github-mcp**, and **obsidian-mcp** are Mac-hosted (Cloudflare tunnel),
  need the Mac on and `*.schnapp.bet` in the network allowlist.
- **Credentials** — one 1Password Service Account token bootstraps everything; all else resolves from
  `op://` refs. `credentials-map.md` is the reference inventory + rotation changelog. Live-verified: one
  token resolves all secrets off-Mac. The strongest piece of the system.
- **Scheduler + CI** — `.github/workflows/freshness.yml` (secret scan + doc-freshness + op-ref + self-tests),
  `ci-lint.yml` (memory frontmatter), `scheduled-routines.yml` (nightly read-only bundle, runs four passes).
  Mac LaunchAgents drive the heavier `claude -p` routines.
- **Surfaces + templates** — one operating profile per surface; `always-loaded-instructions.md` is the
  hookless equivalent pasted into claude.ai; `templates/user-global-CLAUDE.md` is the canonical copy of
  `~/.claude/CLAUDE.md`.

### What is load-bearing (absolute core) vs not

- **Absolute core** (remove and a guarantee breaks): the 7 global rules + their load path; hooks
  session-start-gate, stop-push-gate, session-end-backup, no-force-push-guard, secret-scan-on-write,
  capture-nudge; hookless-fallback skills session-hygiene/surface-check/status; the secrets stack
  (1Password SA token + op-mcp + vault-resolve/rotate-secret/cleanse-secrets + secrets-leak-reviewer +
  scan-secrets.sh); the memory lane + memory-mcp; mac-mcp; the trackers; `freshness.yml`; the generators
  and detectors (gen-catalog, check-freshness, supersede/stale/frontmatter scans, learning-gate/worker).
- **Nice-to-have** (lose convenience only): all domain skills (etl/sql/appfolio/quickbase/perf/benchmark/
  latency/cache/regex), council/grill-me/grill-with-docs/docs-lookup/context-budget, the 4 commands,
  github-mcp + obsidian-mcp (overlap / Mac-bound, both have fallbacks), the sql-etl-reviewer +
  performance-optimizer agents, the shellcheck hook.
- **Dead weight / not wired**: 5 stub rule modules (activity: data-modeling, policy-procedure, web-tool;
  context: work, personal), the `code-work-machines.md` surface stub, the `infra-health` probe (spec, no
  installed plist).

---

## Part 2 — Current state, reconciled (as of 2026-06-29)

Per handoff 038: Mac autonomy is unblocked (the fix was adding `mac-mcp.schnapp.bet` to the env network
allowlist), all stray session branches were swept (remote is `main`-only, 0 open PRs), web sessions are
policy-bound to `main` (ADR 0017). Since AUDIT (2026-06-26): the dead supersede-orphan scan **is fixed**
(today's SessionStart gate printed `no supersede-orphans`), and `docs/framework.md` landed.

**The through-line: strong against silent drift, weak against silent stop.** The system reliably prevents
*stale data* — CI freshness gate, supersede scan, frontmatter checks, the start-gate. It does **not**
reliably detect when its own *automation has silently died*. Every top gap is an instance of this, and it
just cost real money in production:

- 🔴 **Live production risk (root-caused this session): the SQL backup has not run since 2026-05-03 (~55
  days).** The `weekly-backup.sh` ran clean through May 3 (logs show success + retention pruning) on a
  weekly Sunday-05:00 schedule, but its LaunchAgent plist lives in `~/azure-sql-backups/`, is **not** in
  `~/Library/LaunchAgents/`, and is **not loaded** (`RunAtLoad: false` + unregistered = never re-armed after
  whatever unloaded it). The error log is empty: it did not crash, it stopped being scheduled, and nothing
  noticed. This is the silent-stop enemy exactly, and `infra-health.md` (which would have caught it) is the
  uninstalled probe. **Fix is asks-first** (it kicks a ~7-min export against production data) — commands in
  Part 4 P0.
- 🟡 **The reflective freshness half does not run** (AUDIT B1, the #1 gap vs the owner's #1 goal): memory
  aging / consolidation / weekly review are spec'd but uninstalled; only the read-only doc cron runs
  (9 green runs, verified). The learning-worker LaunchAgent needs reinstall + end-to-end verification
  (handoff 038 #2/#3).
- 🟡 **The Obsidian brain-agent index is stale** (last processed 2026-06-16) and Mac-bound; off-Mac there is
  only a read-only mirror. Same silent-stop shape, no drain alarm.
- 🟢 **Strong, do not regress**: credential portability (one SA token resolves everywhere, live-verified
  off-Mac), cost discipline (every hosted piece on a verified $0 tier, zero embeddings), single-source
  skills, hard git/secret gates (force-push blocker, secret scan), the running read-only cron, day-one
  observability (CI summaries, append-only PROGRESS, sequential handoffs).

---

## Part 3 — What is missing, and per-component improvements

### What is missing (the absent capabilities)

1. **A liveness heartbeat that proves jobs ran and alarms when they did not.** No "job did not fire" signal
   anywhere; the backup proves the cost. `infra-health` is the intended probe but is uninstalled.
2. **The reflective memory loop**: episodic→semantic aging, consolidation, weekly deep review, 90-day
   age-flagging, "wiki grows from questions." Spec'd-only or absent (AUDIT B).
3. **The eval/promote gate** — the keystone behind capture, wiki-grows, skill extraction, and self-learning
   (AUDIT cross-cutting). Capture is nudge-only; there is no pre-acceptance review of agent-authored edits.
4. **Enforced session write-back**: authoring of facts/handoff/PROGRESS is advisory; only push of existing
   commits hard-blocks (AUDIT A8).
5. **Tool-call instrumentation**: no per-tool counters, so the periodic prune has no frequency×impact data
   (AUDIT G3).
6. **A bounded-iteration cap + an in-repo verify skill** (delegated to external `superpowers` today; AUDIT I1).
7. **Enforced token budget** (awareness skill exists, no coded cap; AUDIT D11).
8. **One memory frontmatter schema** — three disagreeing schemas exist today (AUDIT C5).

### Per-component improvement review

**MCPs / connectors.**
- Split the over-broad **mac-mcp** (~25 tools) into scoped servers (shell / sql / services / actions); it
  also duplicates op-mcp's secret tools. Reconcile **github-mcp** (~43 tools, AUDIT G1) against the native
  GitHub MCP + the cloud git-write path — it is convenience that overlaps and dies when the Mac sleeps.
- Add **per-call telemetry** to all connectors so the next prune is data-driven (AUDIT G3).
- Add a free **keep-warm ping** to the two Render connectors to kill the ~30-60s cold start (AUDIT K4).
- Consider **retiring memory-mcp** if hookless surfaces go unused — shrinks the credential blast radius
  (AUDIT K-audit). Decide, do not leave implicit.
- Commit the Obsidian `_brain/_index.json` to the GitHub mirror so `get_index` has an off-Mac read path
  (AUDIT A1/E1).

**Hooks.**
- Add a **SessionEnd write-back heuristic**: flag a substantive session that produced no memory/handoff/
  PROGRESS delta (AUDIT A8). Make `session-hygiene` the default closing step in the always-loaded block.
- Add a **PreToolUse guard for destructive/outward commands** (deploys, schema SQL, LaunchAgent installs)
  absent a confirmation token (AUDIT I3). The backup install is exactly this class.
- Keep the recently-fixed supersede scan; it is the model for deterministic anti-stale signals.

**Skills.**
- Author an **in-repo verify/iterate skill with a hard 3-5 iteration cap**, or ADR the decision to keep
  verification external (AUDIT I1/F5).
- Decide **skill versioning**: add `version:` frontmatter, or ADR git-history-as-versioning (AUDIT F3).
- Note: `learn-route` is present on disk and in CATALOG but is **not surfaced in this session's skill list**
  — a marketplace/registration check, not a missing file.
- Domain skills are fine and lean; no action.

**Rules.**
- Fill or delete the **5 stub modules** (do not leave placeholders pretending to be capabilities).
- **Trim `working-style.md` under 300 words** — AUDIT D8 measured it at 404w, over the budget the system
  sets for its own always-loaded layer.
- Add a **one-area-per-run bleed guard** + an `_adhoc`/global-only fallback line in `do.md` step 2
  (AUDIT D2/D5/D6).

**Memory.**
- **Normalize to one frontmatter schema** and backfill `source:`/`updated:` on the files missing them
  (AUDIT C5/C9). CI already checks frontmatter, so this closes the loop.
- **Resolve the memory-model question via ADR**: keep the deliberate two-lane model (and document it as the
  substitute for working/episodic/semantic) or add tiers (AUDIT C4). Unblocks correct scoring elsewhere.

**Scheduler / CI.**
- **Install and confirm the LaunchAgents** (backup, learning-worker, then memory-consolidation + infra-health),
  recording `launchctl list` confirmation in PROGRESS so "it runs" is provable, not assumed.
- Add a **weekly deep-review cron** writing a dated note to a new `reviews/` dir (AUDIT B3).
- **Adopt `last-verified:`** on key docs so the `check-freshness.sh` second gate goes live (zero adopters
  today), and add a memory age-flag pass to the nightly bundle (AUDIT B2/B4).

---

## Part 4 — Prioritized action plan (sequenced, deduped)

Merges AUDIT's worklist (Tiers 0-4) with handoff 038's open items. The ordering reflects the silent-stop
north star and the live production risk.

**P0 — operational, do first (asks-first where noted):**
1. **Restore the SQL backup job** — **RESOLVED 2026-06-29.** Schedule armed (LaunchAgent installed/loaded)
   and a fresh `schnapp-bet-20260630.bacpac` (344M) verified-exported, backfilling the gap. The failure had
   two causes, neither the credential issue the raw error implied: the LaunchAgent was never installed into
   `~/Library/LaunchAgents`, and `weekly-backup.sh` still targeted the pre-rename DB name (`sports-modeling`,
   renamed to `schnapp-bet` after 2026-05-03). Fixed both. Separately, host `sqlcmd` is broken
   (`brew install unixodbc`); the backup uses `sqlpackage` and is unaffected. Install commands retained below.
2. **Learning-worker auth: DONE 2026-06-29 (ADR 0019).** Switched the worker to the **Claude subscription**
   OAuth token (`CLAUDE_CODE_OAUTH_TOKEN`), verified headless end-to-end. The earlier `ANTHROPIC_API_KEY`
   sanction was a misdiagnosis: the stored OAuth token was malformed (leading space + wrapping quotes), not
   a CLI-version limit. Cleaned the vault value, repointed `LEARNING_CLAUDE_TOKEN_REF`, reinstalled the plist
   from template. Worker reasoning now bills the subscription, not the API. The next queued capture (or the
   30-min backstop) exercises the live run; its log will show `-> CLAUDE_CODE_OAUTH_TOKEN`.
3. **Refresh the 2 stale memory facts** flagged by the start-gate: `keep-tracker-current`, `obsidian-state`
   (supersede-not-append).

**P1 — close the silent-stop gap (the north star):**
4. **Install + schedule `infra-health`** and make it alarm on: a LaunchAgent that should be loaded but is not,
   a backup older than its interval, and an Obsidian index drain older than N hours. This is the probe that
   would have caught P0 #1.
5. **Install + confirm `memory-consolidation`**; add the **weekly deep-review cron**.
6. **Adopt `last-verified:`** on key docs + add a **memory age-flag pass** to `run-ci-routines.sh`.

**P2 — substrate hygiene:**
7. **Normalize memory frontmatter** to one schema + backfill `source:`/`updated:`.
8. **SessionEnd write-back heuristic**; make `session-hygiene` the default closing step.
9. **Trim `working-style.md` <300w**; **fill or delete the 5 stub modules**; add the **bleed guard +
   `_adhoc` fallback**.
10. **ADR the memory-model question** (two-lane vs tiers) and the **main-only stance**.

**P3 — keystone:**
11. **Build the eval/promote gate** (routes agent-authored rule/memory edits to a staged, reviewable commit
    before acceptance). Unlocks capture-as-persistence, wiki-grows-from-questions, skill extraction, and
    safe self-learning — the highest checks-unlocked per unit effort (AUDIT Tier 3).

**P4 — tool discipline & polish:**
12. **Split mac-mcp** into scoped servers; **reconcile github-mcp**; add **per-tool call counters** + a
    frequency report routine.
13. **Author the bounded-iteration verify skill** (hard 3-5 cap) or ADR keeping verification external.
14. Add a **token-budget signal** (CI or start-gate). Remove committed **`dist/` + `node_modules/`** from
    op-mcp/memory-mcp if the deploy builds from source (verify the Dockerfiles first).
15. Add a free **keep-warm ping** to the Render connectors.

### P0 #1 — exact commands to restore the backup (run on the Mac, asks-first)

```bash
# Inspect what will run first (read-only)
cat ~/azure-sql-backups/weekly-backup.sh

# Install the LaunchAgent so it survives reboots, then load it
cp ~/azure-sql-backups/bet.schnapp.bacpac-backup.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/bet.schnapp.bacpac-backup.plist
launchctl list | grep bacpac          # confirm it is registered

# Optional: take one backup NOW (55 days of unbacked data) — ~7 min export against production
~/azure-sql-backups/weekly-backup.sh && tail -5 ~/azure-sql-backups/weekly-backup.log
```

After this lands, P1 #4 (the infra-health probe) is what keeps it from silently dying again.

---

## Part 5 — Don't regress (verified strengths)

Credential portability and the stateless-processor inversion (live-verified off-Mac); cost/OSS discipline
(a clean sweep, every hosted piece on a verified $0 tier); the running read-only nightly cron (9 green runs);
single-source skills + the clean core/thin-client connector seam; the hard gates (force-push blocker,
secret scan, read-only specialist agents); day-one observability. And, new since AUDIT, the now-working
supersede-orphan scan. Preserve these when implementing the above.
