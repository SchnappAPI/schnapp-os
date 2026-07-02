# schnapp-os — Audit against the Agentic-OS Target Spec

> **Point-in-time snapshot (2026-06-25), superseded and not maintained.** It scores a much earlier
> tree (pre vault-split ADR 0023 and pre plugin-flatten ADR 0024) and describes structure that has
> since changed. For current state read [PROGRESS.md](PROGRESS.md), [decisions/](decisions/), and the
> live plans under [docs/superpowers/plans/](docs/superpowers/plans/). Kept as frozen history (like
> `handoffs/`); do not read its scores as current.

*Read-only audit. Scores the repo against `master-instructions-adapted.md` (target) and `master-rules.md` (checklist), weighted by the owner's priorities: **Fresh > Global > Consistent > Quick > Accurate**, with groups **A (portable substrate)** and **B (freshness)** outranking everything below them.*

- **Date:** 2026-06-25
- **Commit / branch audited:** `claude/compassionate-brown-a1cqxy` (working tree clean)
- **Method:** 7 deep subsystem readers → 12 per-group scorers (one per checklist group), each citing concrete paths and verifying *behavior, not keywords*. Several facts were **live-verified** during the audit via the connected MCP servers (see "Live verification" below).
- **Status legend:** ✅ present · 🟡 partial · ❌ absent · ❓ can't determine

---

## 0. Architecture as actually built (important framing)

The repo is **not the vault** the spec describes — it is the **OS/tooling layer** that operates on a vault. The system is three layers, and the audit judges the *combined* system while being precise about which layer provides what:

| Layer | What it is | Portable? |
|---|---|---|
| **`schnapp-os` repo** (this repo) | The OS: plugin rules, hooks, MCP connectors, scheduled-task specs, decisions/handoffs, the git-tracked `memory/` "global lane" | ✅ git, reachable everywhere |
| **Obsidian vault** | The richer knowledge store (Inbox → brain-agent classify → clustered index). Reached via `obsidian-mcp` | 🟡 **Mac-hosted** (decision 0008); brain-agent index unreachable with the Mac off (read-only GitHub mirror only) |
| **`memory/` lane** | Harness auto-memory repointed at the repo via `autoMemoryDirectory`; flat per-fact markdown + `MEMORY.md` index | ✅ git + reachable off-Mac via `memory-mcp` |

**The repo deliberately diverges from the spec in several places** (these are design choices, scored as 🟡/❌ against the literal spec but flagged as intentional where relevant):
- No single `agents.md`; behavior is **federated** across `plugins/core/rules/global/*`, `surfaces/always-loaded-instructions.md`, `memory/README.md`, and `templates/user-global-CLAUDE.md`.
- Memory uses a **two-lane (global/project) scope model**, *not* the spec's three cognitive tiers (working/episodic/semantic). Episodic ≈ `decisions/` + `handoffs/` + `PROGRESS.md`.
- No `index.md`/`/knowledge/raw`/`/wiki`/`/reviews` folders; the index role is split across `CATALOG.md` (generated) and `memory/MEMORY.md` (hand-curated).
- Module gallery/presets/composer were **removed on purpose** (decision 0011 #4 — "subtract rather than complete").

---

## 1. Executive summary

**Overall posture: a real, mature, well-disciplined system whose *portable substrate* (Group A) and *cost/OSS discipline* (Group K) are genuinely strong and partly live-verified — but whose *freshness engine* (Group B), the owner's #1 priority, is the weakest area and is materially weaker than the spec claims.** The half of freshness that runs is a read-only, Mac-independent GitHub-Actions cron (confirmed: **9 consecutive green nightly runs**). The reflective half — episodic→semantic aging, pattern extraction, semantic-drift audit, weekly review, pruning, "wiki grows from questions" — is **spec'd-only** (an uninstalled Mac LaunchAgent) or structurally absent, and the one deterministic supersession signal that *does* run is **dead-on-arrival** due to a confirmed frontmatter-matching bug. Credentials, git-sync, least-privilege, single-source skills, and cost discipline are the standout strengths. The recurring keystone behind many gaps is the **eval/promote gate**, which the repo itself flags as unbuilt.

**Tally:** 72 checks → **20 ✅ present · 37 🟡 partial · 15 ❌ absent.**

| Group | ✅ | 🟡 | ❌ | Priority |
|---|---|---|---|---|
| A · Portable substrate | 3 | 5 | 0 | **P1** |
| B · Freshness engine | 0 | 4 | 4 | **P1 (top)** |
| C · Memory & provenance | 1 | 5 | 3 | P1/P2 |
| D · Context & areas | 1 | 7 | 3 | P2 |
| E · Retrieval | 2 | 2 | 1 | P2 |
| F · Skills & sharing seam | 2 | 3 | 3 | P2 |
| G · Tool discipline | 1 | 2 | 0 | P2 |
| H · Orchestration | 1 | 3 | 0 | P3 |
| I · Operating loops | 2 | 1 | 1 | P2/P3 |
| J · Self-learning | 1 | 1 | 0 | P3 |
| K · Cost / OSS | 5 | 0 | 0 | P2 |
| L · Anti-staleness guards | 1 | 4 | 0 | P1/P2 |

### Top 5 highest-priority gaps (weighted; A/B floated to top)

1. **[B · Fresh] The reflective heartbeat does not run, and there are no memory tiers to reflect over.** `scheduled-tasks/memory-consolidation.md` + `infra-health.md` are Mac-LaunchAgent specs with **no committed plist and no evidence of installation**; only the read-only doc-freshness + sync cron runs. There is no working/episodic/semantic structure, so no episode review, pattern extraction, cited semantic updates, 90-day flagging, weekly `/reviews`, or pruning actually happens. → *This is the single biggest gap against the #1 goal.* **(Effort: M to schedule; L to add tiering.)**

2. **[B/C/L · Fresh] The only deterministic supersession/staleness signals are no-ops — confirmed.** `plugins/core/hooks/session-start-gate.sh:69` matches column-0 `supersedes:` but every real fact file nests it under an indented `metadata:` block (verified against `memory/credentials-state.md:8`), so the orphan scan matches **zero** files. Separately, `check-freshness.sh`'s `last-verified:` check has **zero adopters** (prints "ok: no last-verified docs yet"). So memory facts, vault notes, and prose docs can all go stale with no job catching them. **This is the cheapest high-impact fix (Effort: S).**

3. **[B · Fresh] No active age/staleness detection, no semantic-drift audit, no "wiki grows from questions."** Running staleness detection covers exactly **one** generated doc (`CATALOG.md` diff). There is no N-days-since-review query, no 90-day flag, no running drift audit (semantic-vs-episodic contradiction check), and no mechanism that turns an answered question into a cross-linked page + log. The compounding-freshness behaviors are absent. **(Effort: M–L.)**

4. **[A · Global] No single `agents.md`, and behavior-spec *activation* is not data-resident.** The spec *content* travels via git (good), but it is split across four artifacts and a behavior change must be propagated to several; worse, **activation** is a **manual paste** of `surfaces/always-loaded-instructions.md` on hookless surfaces and a per-machine `~/.claude/CLAUDE.md` on Code. So "every behavior change is one text edit that travels everywhere" is not literally true. **(Effort: M.)**

5. **[A · Global] The knowledge layer has a real single-machine (Mac) dependency, and session write-back is not enforced.** The Obsidian vault's synthesis/index/classifier is Mac-hosted; with the Mac off, only a stale read-only GitHub mirror remains (brain-agent index last processed **2026-06-16**, 6 test notes). And the *authoring* of the end-of-session write (facts/handoff/PROGRESS) is **advisory-only** — only push-of-already-committed work hard-blocks (`session-stop-push-gate.sh`). So "next surface inherits everything" depends on agent compliance, not enforcement. **(Effort: M.)**

> **Cross-cutting keystone:** the **eval/promote gate** (admitted unbuilt in `capture-nudge.sh:24`, deferred in handoff 034) is the common blocker behind gaps in B (wiki-grows), C (capture), F (skill extraction), J (self-learning), and L (diff-review-before-accept). Building it unlocks the most checks per unit effort, but it ranks below the pure-freshness fixes above on the Fresh-first weighting.

### Live verification performed during this audit
- **GitHub Actions API** → `scheduled-routines.yml` has **9 consecutive `event=schedule`, `conclusion=success`** runs (2026-06-17 → 2026-06-25). The daily light heartbeat genuinely runs unattended.
- **`op_health` / `memory_health`** → both deployed connectors returned `authenticated:true` from this **non-Mac** surface (op-mcp integration name matches `op-mcp/src/constants.ts`; memory-mcp returned `repo:SchnappAPI/schnapp-os, memoryFileCount:10`). Credentials + memory are genuinely surface-independent.
- **`get_index`** (Obsidian) → brain-agent index `last_processed: 2026-06-16` (9 days stale at audit), 6 notes in one cluster. The vault synthesis path is real but stale/Mac-bound.
- **Direct file read** → supersede-orphan bug confirmed (`session-start-gate.sh:69` vs `credentials-state.md:8`).
- **Could NOT determine:** whether the `memory-consolidation`/`infra-health` LaunchAgents are installed on the Mac (`mac-mcp shell_exec` returned `unauthorized` during the audit; no plist is tracked in-repo). Recommended check: `launchctl list | grep -i -E 'consolidat|brain|infra'` on the Mac.

---

## 2. Per-group scoring

### A. Portable substrate & surface-independence  **[P1]**

*Posture: the durable OS substrate is real and largely live (git store, off-Mac creds + memory verified). Weaknesses: no single `agents.md` + manual spec activation, the vault's Mac dependency, and write-back authoring being advisory, not enforced.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Source of truth = version-controlled synced markdown store; nothing stranded on one machine | 🟡 | `memory/README.md`, `connectors/memory-mcp/src/constants.ts`, `decisions/0008-*` | OS substrate is fully portable, but the **Obsidian vault** (index/classifier) is Mac-resident; with the Mac off only a read-only GitHub mirror remains | Commit the vault `_brain/_index.json` to the GitHub obsidian-vault mirror so `get_index` has an off-Mac source; document in `surfaces/README.md` which capabilities degrade when the Mac sleeps | M |
| Git-versioned; commit/push on cadence + after writes; any surface clones/pulls | ✅ | `connectors/memory-mcp/src/github.ts`, `plugins/core/hooks/session-stop-push-gate.sh`, `session-start-gate.sh:35` | Cadence is event-driven (Stop gate blocks unpushed commits) + nightly read-only CI; uncommitted work is advisory only | None required; optionally add a periodic commit nudge for dirty work | S |
| Single `agents.md` behavior spec governs all behavior + travels with data | 🟡 | `surfaces/always-loaded-instructions.md`, `plugins/core/rules/global/`, `memory/README.md`, `templates/user-global-CLAUDE.md` | No `agents.md`; spec federated across 4 files; **activation** is manual paste (hookless) or per-machine `~/.claude/CLAUDE.md` (Code), not data-resident | Treat `always-loaded-instructions.md` as the single canonical spec all surfaces mirror; document the federation + propagation checklist in `surfaces/README.md` | M |
| Store = source of truth; agent = stateless interchangeable processor | ✅ | `.claude/settings.json:3` (`autoMemoryDirectory`), `memory/README.md:14-16`, `connectors/memory-mcp/src/tools.ts` | — (verified: read `owner-working-preferences.md` off-Mac with frontmatter intact) | None; optionally confirm `autoMemoryDirectory` auto-loads on the live Mac post-trust-dialog | S |
| Credentials resolve on every surface from a portable store | ✅ | `credentials-map.md:12-19`, `connectors/op-mcp/src/*`, `render.yaml` | — (**live-verified** `op_health authenticated:true` off-Mac; one SA token resolves all `op://` refs) | Add a post-rotation `op_health` gate so a rotation that breaks off-Mac resolution is caught automatically | S |
| Remote-execution path for long jobs, reachable from any surface; survives disconnection | 🟡 | `connectors/mac-mcp/server.py:198-221` (shell), `:357-368` (workflow_trigger), `.github/workflows/scheduled-routines.yml` | `shell_exec` is synchronous, 600s cap, no detach → arbitrary long Mac jobs die with the call; only GitHub-Actions-shaped jobs survive disconnection | Add a `mac-mcp` detached-job tool (`setsid`/`nohup` + logfile + poll/tail), or document that long jobs must be authored as GitHub Actions workflows | M |
| Session lifecycle enforced (sync→index→area→memory→work→capture→update→push) | 🟡 | `session-start-gate.sh`, `capture-nudge.sh`, `session-stop-push-gate.sh`, `session-end-backup.sh`, `memory/README.md` | Sync + push enforced; **detect-area, inject-memory-as-a-step, update-index/log not code-enforced**; capture is nudge-only; supersede scan dead (item B/C); Code-only | Fix the supersede scan (see L); build the eval/promote gate so capture persists; tighten `session-hygiene` skill for hookless surfaces | L |
| Session write-back is mandatory, not optional | 🟡 | `session-end-backup.sh`, `session-stop-push-gate.sh:36-50`, `surfaces/always-loaded-instructions.md:18` | Only **push of existing commits** hard-blocks; **authoring** of facts/handoff/PROGRESS is advisory (SessionEnd can't block) | Add a SessionEnd heuristic that flags a substantive session with no memory/handoff/PROGRESS delta; make `session-hygiene` the default closing step in the always-loaded block | M |

### B. Freshness engine  **[P1 — top priority]**

*Posture: bifurcated. The read-only, Mac-independent cron is **confirmed running** (9 green nightly runs). The reflective/memory heartbeat and every age/drift/prune/wiki-growth behavior is spec'd-only or absent, and the deterministic memory signal is broken. This is the weakest group against the most important goal.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Scheduled heartbeat runs without the user (daily light + weekly deep) on a remote machine | 🟡 | `.github/workflows/scheduled-routines.yml` (cron `17 8 * * *`), `scheduled-tasks/memory-consolidation.md`, `infra-health.md` | Daily light **confirmed running**; **no weekly cadence at all**; the reflective "deep" half is an **uninstalled** Mac LaunchAgent | Add a weekly cron (or commit a LaunchAgent installer/plist) and record install confirmation (`launchctl list`) in PROGRESS so the deep heartbeat is provably running | M |
| Daily heartbeat: archive working→episodic >48h, review episodes, extract patterns, cited semantic updates, brief, flag 90+d | ❌ | `memory/` (no working/episodic/semantic dirs), `run-ci-routines.sh`, `session-start-gate.sh` | Every sub-step structurally absent — no tiers to age between; daily cron does zero memory work | Decide via ADR whether to add episodic/semantic structure or formalize the two-lane model as equivalent; add a 90-day age-flag pass; fix the supersede scan | L |
| Weekly deep review → `/reviews` (re-read month, unlinked connections, drift, user model) | ❌ | `.github/workflows/`, `scheduled-tasks/` | No weekly job, no `/reviews` dir, no episodic re-read, no drift flag | Add a weekly cron / LaunchAgent running `claude -p` over recent handoffs/decisions/PROGRESS, writing a dated note to a new `reviews/` dir | L |
| Staleness detection runs actively (N-days-not-reviewed, contacts, stale-but-linked) | 🟡 | `plugins/core/scripts/check-freshness.sh`, `.github/workflows/freshness.yml` | Covers only generated-doc drift (`CATALOG.md`); the `last-verified:` check has **zero adopters** (live no-op); no age/contacts/stale-linked scans | Adopt `last-verified:`/`updated:` on real docs, or add an age-based scan over `memory/` after normalizing frontmatter (item C5) | M |
| Semantic-drift audit (compare semantic vs episodic; flag contradictions) | ❌ | `scheduled-tasks/memory-consolidation.md`, `session-start-gate.sh` | The reframed equivalent (consolidation proposal) is asks-first, unscheduled, **uninstalled**; only deterministic contradiction signal is the **broken** supersede scan | Install + schedule `memory-consolidation` as the drift-audit equivalent; fix the supersede scan to match indented keys | M |
| `index.md` auto-regenerated + timestamped; read first | 🟡 | `plugins/core/scripts/gen-catalog.sh`, `CATALOG.md`, `memory/MEMORY.md` | No `index.md`; `CATALOG.md` is generated but **deliberately untimestamped** (`gen-catalog.sh:11`); `MEMORY.md` is read-first but **hand-curated**, untimestamped | Add a generated, dated memory index (or a generated section in `MEMORY.md`) outside the CI-diffed region to avoid the "no timestamps for stable diff" tension | M |
| Wiki grows from questions (answer → write/update cross-linked page + log) | ❌ | `docs/intent-capture-2026-06-23.md:31`, `capture-nudge.sh` | Entirely absent; learning loop is "mostly absent — only distill/route/retrieve"; capture is correction-triggered nudge-only | Depends on the eval/promote gate; build as a reviewed-commit flow (write page via `obsidian-mcp write_note` + PROGRESS line), not autonomous self-rewrite | L |
| Pruning runs (dedupe, consolidate, rotate 90+d logs, archive dormant; human-in-loop deletes) | 🟡 | `plugins/core/scripts/backup-archive.sh`, `scheduled-tasks/memory-consolidation.md`, `handoffs/034-*` | Human-in-loop-on-deletes met by policy; actual ops absent — `backup-archive.sh` only mirrors (never deletes); **no log rotation, no dormant-archive, no automated dedupe**; consolidation uninstalled | Install/schedule `memory-consolidation` to generate dedupe/consolidate proposals; add an asks-first log-rotation/dormant-archive step for PROGRESS/old handoffs | M |

### C. Memory substrate & provenance  **[P1/P2]**

*Posture: substrate is genuinely portable (git markdown, no DB) and provenance-as-a-rule is real. But the spec's raw/wiki/processed ingest, three tiers, 7-field frontmatter, retained-`superseded:true`, and `log.md` are absent or implemented as a deliberate-but-different model — and the substrate that preaches single-source runs three disagreeing frontmatter schemas.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Memory lives in the vault (not a DB on one machine) | ✅ | `memory/README.md:13-16`, `.claude/settings.json`, `connectors/memory-mcp/src/constants.ts` | — (git markdown, no DB; reachable off-Mac via memory-mcp) | None | — |
| Raw vs synthesized separation (`/knowledge/raw` → `/wiki`) | ❌ | `connectors/obsidian-mcp/server.py`, `obsidian-mcp/README.md` | No raw/wiki folders in repo; the only ingest/classify pipeline is the **off-repo Mac brain agent** (not surface-independent) | Document the Obsidian Inbox→brain-agent flow as the equivalent and bring the brain agent into version control, OR record raw/wiki as a deliberate non-goal in `decisions/` | L |
| After ingest, source moves to `/raw/processed` (dedup + audit) | ❌ | `memory/`, `connectors/obsidian-mcp/server.py` | No processed/ staging; `memory_write` overwrites in place; dedup is manual/asks-first | Bring brain-agent processing into the repo, or record in `decisions/` that ingest-staging is intentionally not modeled | L |
| Three memory layers as folders (working/episodic/semantic) | ❌ | `memory/README.md`, `decisions/`, `handoffs/`, `PROGRESS.md` | Deliberate orthogonal **two-lane (global/project)** model; episodic ≈ decisions+handoffs+PROGRESS; "semantic written by freshness jobs only" is false (no installed job writes) | Make the substitution explicit in `memory/README.md` (it currently doesn't reject the tiering); add tiering only if genuinely wanted (large build) | L |
| Every note carries `source/last-reviewed/superseded/area/type/importance/agent-written` | 🟡 | `memory/README.md:40-49`, `credentials-state.md`, `owner-working-preferences.md`, `connectors/memory-mcp/src/tools.ts` | Only `source` (+ad-hoc `type`) present; **3 disagreeing schemas** (README flat vs on-disk nested `metadata:` vs hybrid); `last-reviewed/superseded-bool/area/importance/agent-written` missing or renamed; 7/8 files lack `updated:` | Normalize all `memory/*.md` to ONE schema; update `README.md:40-49` to match `buildFact()`; add missing freshness fields; one-time migration | M |
| Self-evolving capture every session → patterns/mistakes/decisions/context | 🟡 | `capture-nudge.sh`, `session-end-backup.sh:12-13`, `memory/README.md:78-86` | Capture is **triggered, not extracted**; nudge writes nothing; SessionEnd advisory-only; only explicit corrections (grep) handled | Build the eval/promote gate so a session-stop step can deterministically stage captured facts; live-prove the SessionEnd hook on the Mac | M |
| `log.md` audit trail of every capture/answer/update | 🟡 | `PROGRESS.md`, `handoffs/`, `decisions/`, `memory/keep-tracker-current.md` | No `log.md`; equivalent is PROGRESS+handoffs+decisions+git at **commit/session granularity**, not per-answer; no answer logging | Document PROGRESS+git+handoffs as the intended equivalent; finer per-event logging only if wanted (new hook; against the "subtract" principle) | M |
| Supersession: `superseded:true` retained, filtered from retrieval, replacement linked | 🟡 | `memory/README.md:32-33`, `session-start-gate.sh:69`, `connectors/memory-mcp/src/tools.ts` | Repo **deletes** the old fact (audit only in git) rather than retaining+filtering; the lone deterministic check is **dead** (column-0 vs indented key — confirmed) | Fix `sed` to match indented keys (or normalize frontmatter); decide whether retrieval-time filtering of retained-superseded notes is wanted | S |
| Provenance enforced — answers cite source; no unsourced assertion as fact | 🟡 | `plugins/core/rules/global/verify-before-asserting.md`, `secrets-as-references.md` | Enforced as a soft always-loaded **rule**, not a hard gate; 2/8 fact files lack `source:` | Backfill `source:` on `owner-working-preferences.md`, `op-wrap-token-unquoted.md`; add CI that every memory file carries `source:`+`updated:` | S |

### D. Context layer & areas  **[P2]**

*Posture: organized primarily **by function** (lang/coding/activity/tool modules) with **area** as a thin 2-file stub layer, plus a real git-tracked memory wing. The deeper area-pack machinery (\_adhoc, per-area data-scope/decisions/voice, bleed guard, graduation, manifest-driven loading) is largely absent or was deliberately removed.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Organized by function and by area, with an agent-memory wing | 🟡 | `plugins/core/rules/modules/{activity,coding,lang,tool,context}`, `.claude/settings.json` | Function-organization + memory wing present; **area** is a 2-file leaf subfolder (`context/work.md` 61w, `personal.md` 66w), both stubs | Promote `context/` to a richer per-area structure, or accept thin-stub design and adjust the expectation | M |
| Areas = work / personal / `_adhoc` over shared `/global` | 🟡 | `context/work.md`, `context/personal.md`, `rules/global/` | Only work + personal over global; **no `_adhoc`/inbox/fallback area** | Add `context/_adhoc.md` (even a stub), or document that unmatched tasks run on `/global`-only by design | S |
| Tool layer global; only context/conventions/data-scope per-area | ✅ | `commands/do.md`, `templates/project-CLAUDE.md`, `connectors/`, `context/work.md` | — (connectors/skills global; area files carry only conventions + a data-sensitivity line) | None | — |
| Each area pack declares voice deltas, conventions, `data-scope.md`, `decisions-log.md` | ❌ | `context/work.md`, `context/personal.md`, `decisions/` | Single thin `.md` each; no `data-scope.md`, no per-area `decisions-log.md`, no voice deltas | Add `data-scope.md`+`decisions-log.md`+voice under `context/work/` & `context/personal/`, or document the deliberate single-file design | M |
| Never load two areas' conventions in one run (bleed guard) | ❌ | `rules/global/naming-discipline.md:14-15`, `context/` | Only a **language-level** scoping analog exists; nothing stops `work.md`+`personal.md` loading together | Add an explicit one-area-per-run rule in `context/` or `do.md` step 2; or path-scope area modules like lang modules | S |
| Fallback: unmatched → `/global` + request; never force-fit | 🟡 | `commands/do.md`, `surfaces/always-loaded-instructions.md` | Classify-or-ask present, but no explicit "global-only, no force-fit" statement and no `_adhoc` landing zone | Add one line to `do.md` step 2: when no area matches, compose global only, don't force an area | S |
| Graduation rule (`_adhoc` → own pack after ~3 / 20–30 sessions) | ❌ | `commands/do.md`, `docs/schnapp-os-research-and-decisions-2026-06-23.md`, `context/personal.md` | No area-graduation rule, no recurrence threshold; only a *procedure→skill* graduation concept | Add a graduation rule with threshold to `knowledge-capture.md` once `_adhoc` exists | S |
| Three loading tiers (always-load ~3–5 files <300w; context-load; on-demand) | 🟡 | `templates/user-global-CLAUDE.md`, `commands/do.md`, `templates/project-CLAUDE.md` | Tiers exist, but **7** always-load files not 3–5; `working-style.md` **404w** (over), `anti-stale.md` 299w; Tier-2 is manual `@import` | Trim `working-style.md` <300w (or split); consider consolidating 7 global rules toward 3–5 | M |
| Loading driven by `rules.yaml`/`manifest.json` (+ optional classifier) | 🟡 | `commands/do.md`, `gen-catalog.sh`, `templates/user-global-CLAUDE.md` | No manifest (removed per 0011 #4); `paths:` frontmatter is metadata-only (read by `gen-catalog.sh`, not a loader); classifier exists as LLM judgment in `/do` | Accept the deliberate no-manifest design, or wire the existing `paths:` frontmatter into a runtime loader | L |
| Files: when-to-use header, 200–600w, facts/rules/procedures separated, atomic, linked, versioned | 🟡 | `rules/global/anti-stale.md`, `skills/context-budget/SKILL.md`, `rules/modules/lang/python.md` | Atomic/linked/versioned met; "when-to-use" lives on **skills** not rule files; modules **far under** 200w floor (61–123w) — deliberately leaner | Accept lean-by-design (adjust expectation), or add a one-line "use when" to each module's frontmatter | M |
| Token budget respected (~20–40% cap, memory ≤20–30%; drop lowest first) | 🟡 | `skills/context-budget/SKILL.md`, `memory/README.md` | Budget **awareness** skill + structural memory cap exist, but **no numeric cap coded/gated**; manual audit only | Bake numeric thresholds into `context-budget/SKILL.md` + a lightweight CI/hook check, or document budget held by lean files + manual audit | M |

### E. Retrieval  **[P2]**

*Posture: deliberately lean and free — substring/keyword over markdown + a brain-agent pointer/cluster index, **zero embeddings/vector/graph**, which honors "vector only as volume demands" by absence. Wiki-synthesis-at-ingest is real but Mac-bound; area-scoping exists as primitives but no automatic active-area filtering.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Default = wiki-synthesis + pointer index (synthesize once at ingest) | 🟡 | `connectors/obsidian-mcp/server.py:459-481`, `obsidian-mcp/README.md:22-23`, `skills/docs-lookup/SKILL.md:27-37` | Synthesis engine is **off-repo, Mac-resident** (unverifiable/stale here); the in-repo `memory/` lane does **zero** ingest synthesis (hand-authored facts + hand-curated index) | Verify the brain agent actually runs (`get_index` populated, not stale); document the GitHub mirror as the off-Mac read path; or add a light ingest-synthesis step for `memory/` | M |
| Keyword/SQL for exact identifiers, structured data, compliance | ✅ | `obsidian-mcp/server.py:407-434`, `memory-mcp/src/tools.ts:182-225`, `mac-mcp sql_query` | — (substring keyword search + direct SQL for business data) | None; note substring is exact (use precise strings) | S |
| Hybrid (keyword + semantic + re-rank) is default *when* vector used | ❌ | `memory-mcp/src/tools.ts`, `obsidian-mcp/server.py`, research doc:79 | No vector retrieval anywhere, so the conditional is unmet by precondition; no hybrid scaffold to switch on | Leave as-is (gated on vector use, deliberately deferred); if volume forces semantic, add a fusion layer behind the existing search tools | M |
| Semantic/vector + graph added only as volume demands | ✅ | `memory-mcp/src/tools.ts`, research doc:79, `obsidian-mcp/server.py:469-481` | — (honored by documented deliberate absence; only "graph-ish" is brain-agent clusters) | None; optionally add a concrete trigger threshold to the research doc | S |
| Retrieval is area-scoped (filter active area, optionally merge global) | 🟡 | `obsidian-mcp/server.py:408-434`, `memory-mcp/src/tools.ts:182-237`, `context/work.md` | Primitives exist (`search_notes folder=`, memory `scope` lane) but **manual**; `memory_search`/`memory_index` have **no scope filter**; no auto active-area detection; area content is stubs | Add a scope/area filter to `memory_search`/`memory_index`; have `/do` or the start-gate set active area and pass it; flesh out the area files | M |

### F. Skills / capabilities & the sharing seam  **[P2]**

*Posture: genuinely strong single-source-of-truth (22 prose skills that compose by reference without duplication) and a clean core/thin-client split in the connectors. Diverges hard on "production module" machinery: no skill versions, no `{status,data,meta}` on skills, no capability-prompt library (pruned), and the extraction/graduation loop is deferred behind the unbuilt eval gate.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Skills defined once in `/skills`; consumers consume, never own | ✅ | `skills/etl-pipeline-build/SKILL.md`, `skills/appfolio/SKILL.md`, `skills/council/SKILL.md` | — (all 22 under `plugins/core/skills/`; compose-by-reference, no duplicated rule prose) | Optionally enforce no-duplication in CI | S |
| Core logic separated from thin clients (expose as config, not rewrite) | ✅ | `connectors/op-mcp/src/`, `connectors/memory-mcp/src/`, Dockerfiles | — (transport `index.ts`+`auth.ts` over core `onepassword.ts`/`github.ts`; same core shipped to multiple surfaces by config) | Already satisfied at connector layer; wrap skills in a thin MCP tool if ever invoked programmatically | M |
| Skills versioned (highest used unless pinned) | ❌ | `skills/council/SKILL.md`, `skills/status/SKILL.md` | Every SKILL.md frontmatter has only `name`+`description`; **no `version:`**; selection rule N/A | Add `version:` + resolution convention, or document git history as the chosen versioning substrate (matches "subtract") | M |
| Single responsibility + `{status,data,meta}` envelope + semantic fields + model-facing descriptions | 🟡 | `skills/context-budget/SKILL.md`, `memory-mcp/src/tools.ts`, `op-mcp/src/tools.ts` | Single-responsibility + descriptions strong; the structured envelope lives only in **connectors** (`structuredContent`+`isError`, not literal `{status,data,meta}`), not in the prose skills | Accept connectors as the envelope home (note in CATALOG), or normalize tool returns to a shared `{status,data,meta}` helper | M |
| Pipeline patterns available; long pipelines pass refs, summarize, keep structured state | 🟡 | `skills/council/SKILL.md`, `etl-pipeline-build/SKILL.md`, `regex-vs-llm-structured-text/SKILL.md`, `agents/performance-optimizer.md` | Linear/fan-out-in/conditional/nested present; **capped feedback loop missing** (council defaults to 1 round, no hard 3–5 cap); structured state is conventional markdown | Add a bounded-iteration rule + an explicit max-round cap to council/grill | S |
| Resilience: errors as data, retry transient w/ backoff, every call instrumented | 🟡 | `rules/modules/coding/error-handling.md`, `etl-pipeline-build/SKILL.md`, `memory-mcp/src/github.ts`, `skills/quickbase/SKILL.md` | Errors-as-data + 429-honoring present; **no general exponential backoff**; "every call instrumented" is per-pipeline guidance, **no connector telemetry** | Promote a bounded-exponential-backoff pattern into a rule/skill; decide whether connectors emit structured per-call logs | M |
| A capability-prompt library exists (tested, reusable) in the vault | ❌ | `plugins/core/rules/`, `decisions/0011`, `decisions/0007` | None; presets layer **deliberately removed** (0011 #4); no `prompts/` anywhere | Accept as deliberate divergence (record it), or create a versioned `prompts/` with an eval note per prompt (reverses 0011 — conscious choice) | L |
| On-demand lightweight skill extraction tied to `_adhoc` graduation | ❌ | research doc:146, `capture-nudge.sh:24`, `decisions/0007` | Whole loop human-in-loop + unscheduled; eval/promote gate **explicitly unbuilt**; no `_adhoc` to graduate from | Build the eval/promote gate + define a concrete graduation threshold / `_adhoc` staging area | L |

### G. Tool discipline (subtraction)  **[P2]**

*Posture: router→specialist is genuinely present and 3/5 connectors are spec-compliant, but the two heaviest connectors blow past 5–10 tools and there is no tool-call instrumentation — the only "audit" was a manual skill prune.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| 5–10 well-scoped non-overlapping tools per agent | 🟡 | `connectors/mac-mcp/server.py`, `github-mcp/server.py`, `op-mcp`/`memory-mcp`/`obsidian-mcp`, `agents/sql-etl-reviewer.md`, `performance-optimizer.md` | Agents lean (3 & 6 tools); op/memory/obsidian = 5/8/7 (ok); **mac-mcp ~25, github-mcp 43**; mac-mcp duplicates op-mcp's secret tools | Split `mac-mcp` into scoped servers (shell/sql/services/actions); reconcile `github-mcp` (43) vs native `mcp__github__*`; document the deliberate op-* duplication | L |
| Breadth via router → specialists (small toolsets), not one bloated agent | ✅ | `commands/do.md`, `agents/performance-optimizer.md`, `agents/sql-etl-reviewer.md`, `skills/council/SKILL.md` | — (`/do` router; scoped specialists; real chaining perf-optimizer→sql-etl-reviewer; council fan-out) | None; specialist bench thin by design (2 agents) | S |
| Tool calls instrumented; periodic audit cuts dead weight + overlap (freq×impact) | 🟡 | `handoffs/034-*`, `decisions/0007`, `mac-mcp/server.py`, `github-mcp/server.py` | Audit **culture** exists (manual 26→22 prune) but **zero instrumentation**; nothing measures frequency×impact; known overlaps un-culled | Add per-tool call counters to connectors + a `scheduled-tasks/` routine reporting frequency to inform the next prune; target the op-* / github overlaps | M |

### H. Orchestration & multi-agent  **[P3]**

*Posture: a real decompose/route/aggregate pattern (`/do` router, council anti-anchoring fan-out, 2-agent bench) and disciplined connector-layer memory-write hygiene. Intentionally thin and human-in-loop; "handoffs" are session-continuity docs, not typed inter-agent envelopes; episodic/semantic not kept as separate tiers.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Reasoning orchestrator decomposes/routes/aggregates; specialists execute | ✅ | `commands/do.md`, `skills/council/SKILL.md`, `agents/performance-optimizer.md`, `agents/sql-etl-reviewer.md` | — (LLM-judgment dispatch + council fan-out + specialist chaining); bench thin by design; hooks "run-verified not live-proven" | Add specialists for other recurring `/do` classes if broader coverage wanted | S |
| Structured handoffs carry task/context/constraints/success-criteria/active-area | 🟡 | `handoffs/034-*`, `handoffs/`, `skills/council/SKILL.md` | Fields present **informally** as markdown headings; these are **session→session** docs, not a typed **inter-agent** envelope; no `active area` travels with `/do` | Define a small handoff frontmatter schema and have council/`/do` emit it, or codify the existing section set as a uniform template | M |
| Single responsibility, clear I/O contracts, graceful failure, idempotency | 🟡 | `memory-mcp/src/tools.ts`, `agents/sql-etl-reviewer.md`, `etl-pipeline-build/SKILL.md`, `error-handling.md` | Strong in connectors (typed schemas, sha-idempotency, retry hints) + agents; **skills have no machine I/O contract**; no bounded-backoff | Add version + output-shape convention to SKILL.md; capture the bounded-retry/backoff pattern into a coding rule | M |
| Multi-agent memory writes: approved-only, structured, review loops, episodic/semantic separate | 🟡 | `memory-mcp/src/tools.ts`, `skills/council/SKILL.md`, `capture-nudge.sh`, `memory/README.md` | Structured entries strong; **"approved-only/review loops" partial** (eval gate unbuilt); **episodic/semantic NOT separate tiers**; supersede deletes (no retrieval filter) + scan bug | Build the eval/promote gate; adopt episodic/semantic tagging or document the decisions+handoffs split; fix the supersede scan | L |

### I. Operating practices & loops  **[P2/P3]**

*Posture: "self-running" practices are deliberately minimal, safe, reversible — and verified strong (1 nightly read-only cron, 9 green runs; asks-first mutation; real hard gates). The single real gap is the generate→evaluate→revise loop with a hard iteration cap.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Loops: generate→evaluate→revise w/ verification skill, specific failure output, hard cap (3–5), escalation, nesting | ❌ | `skills/rules-distill/SKILL.md:64`, `skills/council/SKILL.md`, research doc | Evaluate/revise roles exist informally (grill/council) but **no codified iteration cap, failure contract, escalation, or owned verification skill** (delegated to external `superpowers`); iteration-cap rule is an *uncaptured* backlog item | Promote `rules-distill:64` into a real bounded-iteration rule; author an in-repo verify/iterate skill with a hard cap; or ADR the decision to keep verification external | M |
| No standing 24/7 automation except freshness jobs; rest lightweight/on-demand | ✅ | `.github/workflows/scheduled-routines.yml`, `scheduled-tasks/README.md`, `run-ci-routines.sh` | — (exactly one nightly read-only cron, **9 green runs verified**; everything else on-demand/asks-first) | Keep the single-cron discipline when wiring `memory-consolidation` so it stays asks-first | S |
| Automations: clear boundaries, log reasoning, surface exceptions, reversible (draft over merge) | ✅ | `scheduled-tasks/README.md`, `scheduled-routines.yml`, `capture-nudge.sh`, `run-ci-routines.sh` | — (safe/asks-first classification; Step-Summary logging; self-edits staged as drafts; read-only cron trivially reversible) | When installing the Mac judgment routines, confirm they actually write reports/proposals (the log leg) | S |
| Least-privilege: read-only default, writes to drafts/branches not main, prod behind approval, all logged | 🟡 | `hooks/no-force-push-guard.sh`, `agents/sql-etl-reviewer.md`, `commands/do.md`, `scheduled-routines.yml`, `session-stop-push-gate.sh` | Strong gates (force-push blocker, read-only agents, `contents:read`); but writes are intentionally **main-only** (not branch/draft isolation) and **prod-approval is rule-level, not a hard gate**; no per-call telemetry | ADR the main-only stance; add a PreToolUse guard for destructive/outward commands (deploys, schema SQL) absent a confirmation token, hardening `/do` step 4 | M |

### J. Self-learning  **[P3]**

*Posture: the weakest loop, and the repo says so candidly. Only explicit corrections are wired (a grep nudge, not an extractor); validate/promote is deferred; heartbeat memory-updates don't run. Governance, however, is fully satisfied: all self-edits are deliberate, human-reviewed git commits — no runtime self-rewrite, no fine-tuning.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Four feedback types: explicit, implicit behavioral, eval loops, memory-updates (via heartbeat) | 🟡 | `capture-nudge.sh`, `docs/intent-capture-2026-06-23.md:31`, research doc, `handoffs/034-*`, `scheduled-tasks/memory-consolidation.md`, `rules-distill/SKILL.md` | Only explicit (grep nudge, no auto-extract); **implicit absent**; **eval loop explicitly deferred**; **heartbeat memory-update uninstalled + only proposes** | Build the eval/promote gate; install + confirm the `memory-consolidation` LaunchAgent; add an implicit-behavioral capture signal at SessionEnd; downgrade docs implying the loop is complete | L |
| Changes to `agents.md`/prompts are deliberate reviewed edits — no runtime self-rewrite, no fine-tuning | ✅ | `capture-nudge.sh` (print-only), `rules-distill/SKILL.md` (approve-before-write), `scheduled-tasks/memory-consolidation.md` (propose-not-rewrite), research doc:254-255 | — (all self-edits are diffable git commits; no fine-tuning code anywhere) | None; keep the eval gate deferred until built, as that guards future autonomy | S |

### K. Cost / OSS discipline  **[P2]**  ✅ fully clean

*Posture: genuinely strong and codified as an operating principle. Free/open substrate, zero embeddings, pure-bash heartbeat, every hosted piece on a verified $0 free tier and kept swappable. Both remote connectors live-verified authenticated.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| Core stack free/open: markdown vault + git; no DB at personal scale | ✅ | `connectors/memory-mcp/src/constants.ts`, `memory/`, `credentials-map.md` | — (private git repo of markdown; the only SQL Server is the user's **business data**, not the OS substrate) | None; optionally confirm `backup-archive.sh` mirror runs on the Mac | — |
| Embeddings/semantic on local models + open vector stores (if used) | ✅ | `memory-mcp/src/tools.ts`, `obsidian-mcp/server.py`, research doc | — (no embeddings/vector at all = $0; substring + wiki-links + index; deferral documented) | None | — |
| Extraction/heartbeat reasoning uses a small/cheap model (sub-cent) | ✅ | `check-freshness.sh`, `scheduled-routines.yml`, `memory-consolidation.md`, `commands/do.md:31-33` | — (running heartbeat is **pure bash = free**; LLM routines reuse the Claude subscription, not metered API) | None (the reasoning routines being uninstalled is a *freshness* gap, item B1, not a cost one) | — |
| Paid tools added only if cheap + not OSS-covered; optional/swappable | ✅ | `render.yaml`, `decisions/0004`, Dockerfiles, `decisions/0011` | — (every hosted piece on $0 free tier, justified in an ADR, host-portable Dockerfiles; **live-verified** authenticated) | Optionally wire a free keep-warm ping to remove Render cold-start; re-confirm free-tier terms periodically | S |
| Audit: nothing recurring paid for that a free tool covers | ✅ | `memory-mcp/src/github.ts`, `decisions/0008`, `render.yaml`, `decisions/0011` | — (no recurring spend; the one git-vs-connector redundancy is **deliberate**, justified for off-Mac surfaces; 0008 actively removed a redundant server) | Confirm off-Mac memory usage; if hookless surfaces are unused, retire `memory-mcp` to shrink the credential surface (blast-radius, not billing) | S |

### L. Anti-staleness & hygiene guards  **[P1/P2]**

*Posture: the hygiene layer is real and partly running, but the "self-freshening" claim is materially weaker than the spec. The deterministic CI freshness gate runs; capture is well-scoped; least-privilege/observability are strong. But the supersession detector is dead-on-arrival, the staleness detector covers one doc, inbox processing is off-repo/unverified, and agent edits aren't gated through a review-before-accept step.*

| Requirement | Status | Evidence (path) | Gap | Recommended action | Effort |
|---|---|---|---|---|---|
| No content goes stale without a job to catch it (heartbeat + staleness + supersession all live) | 🟡 | `scheduled-routines.yml`, `check-freshness.sh`, `session-start-gate.sh:62-82`, `freshness.yml`, `memory/credentials-state.md` | Heartbeat (read-only) live; **supersession scan non-functional** against nested frontmatter (confirmed bug); staleness covers **one** generated doc; reflective heartbeat uninstalled → memory facts, vault notes, prose docs can go stale uncaught | Fix `session-start-gate.sh:69` to match indented `supersedes:` + add a unit test vs `credentials-state.md`; adopt `last-verified:`/`updated:` or add an age-flag pass; install `memory-consolidation` | M |
| Capture selective (decisions/patterns/observations, not routine completions) | ✅ | `capture-nudge.sh`, `rules/global/knowledge-capture.md:7-11`, `decisions/`, `handoffs/`, `memory/` | — (precision-over-recall grep; durable-facts-only routing; nothing auto-captures routine completions) | None (under-capture risk, not a noise risk) | S |
| `/raw` (and inboxes) are actually processed — not a dumping ground | 🟡 | `connectors/obsidian-mcp/server.py`, `obsidian-mcp/README.md`, `decisions/0008` | Right shape (Inbox→classify→index) but processor is **off-repo Mac brain agent, unverified running** (index stale 2026-06-16); no repo-side drain check | Add a check reading `get_index().last_processed` that flags unprocessed items older than N hours (in `infra-health.md`/`status`); confirm the Mac brain-agent LaunchAgent is installed | M |
| Agent edits diff-reviewed via version history before acceptance; human-in-loop on deletes/prunes | 🟡 | `capture-nudge.sh:24`, `scheduled-tasks/README.md`, `session-stop-push-gate.sh`, `backup-archive.sh`, `handoffs/034-*`, `no-force-push-guard.sh` | Human-in-loop-on-deletes strong; but **no pre-acceptance review gate** — eval/promote gate unbuilt; acceptance = the same commit (post-hoc git review only) | Build the eval/promote gate: route agent-authored rule/memory edits to a branch/staged commit for human approval before merge (infra already exists) | L |
| No over-engineering / token bloat / missing error handling / skipped QA / over-broad skills / unversioned context / no observability | 🟡 | `commands/do.md`, `skills/council/SKILL.md`, `mac-mcp/server.py`, `github-mcp/server.py`, `context-budget/SKILL.md`, `error-handling.md`, `decisions/0011`, `PROGRESS.md`, `handoffs/` | Mostly strong (lean orchestration, real error-handling, day-one observability via CI/git/PROGRESS/handoffs, versioned context); gaps: **no enforced token budget**, **mac-mcp 26 + github-mcp 43 tools** (over-broad/overlap), QA-before-delivery discretionary with no iteration cap | Add a lightweight token-budget CI/start-gate signal; split/reconcile the two heavy connectors; codify a hard 3–5 iteration cap in QA skills | M |

---

## 3. Prioritized worklist (build/fix order — A & B gaps first)

Ordered by the owner's weighting (Fresh > Global > …), with A/B floated up. Each item points at the real paths.

**Tier 0 — cheapest fix with outsized freshness impact (do first):**
1. ✅ **DONE (this branch).** **Fixed the supersede-orphan scan** so the one deterministic anti-stale signal actually fires. The detection logic was extracted from `session-start-gate.sh` into a frontmatter-aware, indentation-tolerant, **unit-tested** script: `plugins/core/scripts/check-supersede-orphans.sh` (reads `supersedes:` from the YAML frontmatter at any indentation, incl. nested under `metadata:`; skips prose values; strips `[[wikilink]]`/quotes), wired back into `session-start-gate.sh` §3, with `plugins/core/scripts/tests/test-supersede-orphans.sh` (regression case = an *indented* `supersedes:` the old column-0 scan missed, plus the real `memory/credentials-state.md`) now run by `.github/workflows/freshness.yml`. *(B/C/L · S)*

**Tier 1 — Freshness engine (Group B, top priority):**
2. **Install + schedule the reflective heartbeat.** Commit a LaunchAgent plist/installer for `scheduled-tasks/memory-consolidation.md` (+ `infra-health.md`), or add a second weekly cron; record `launchctl list` confirmation in `PROGRESS.md`. *(B1/B5/B8 · M)*
3. **Add age/staleness detection** beyond the single generated doc: normalize `memory/` frontmatter (Tier 2 item) then add a 90-day/`updated:`-age flag pass to `run-ci-routines.sh`; adopt `last-verified:` on key docs so `check-freshness.sh` check (2) goes live. *(B2/B4 · M)*
4. **Stand up the weekly deep review + `/reviews`** (re-read recent handoffs/decisions/PROGRESS, surface unlinked connections, flag drift) as a weekly `claude -p` routine writing a dated `reviews/` note. *(B3 · L)*
5. **Decide the memory-model question via ADR:** keep the two-lane model (and explicitly document it as the substitute for working/episodic/semantic in `memory/README.md`) **or** add tiers. This unblocks correct scoring of B2, C4, H4. *(C4/B · M for the ADR)*

**Tier 2 — Global / substrate (Group A):**
6. **Normalize memory frontmatter to one schema** (`name/scope/source/updated/supersedes` consistently, nested or flat — pick one) and update `memory/README.md:40-49` + `memory-mcp buildFact()` to match; backfill `source:`+`updated:` on the 2–7 files missing them. Prereq for items 1, 3, and provenance CI. *(C5/C9 · M)*
7. **Consolidate the behavior spec.** Make `surfaces/always-loaded-instructions.md` the single canonical spec every surface mirrors; document the federation map + propagation checklist in `surfaces/README.md`. Reduce the manual-paste activation gap. *(A3 · M)*
8. **Harden write-back.** Add a SessionEnd heuristic that flags a substantive session with no memory/handoff/PROGRESS delta; make `session-hygiene` the default closing step in the always-loaded block. *(A8 · M)*
9. **Close the vault Mac-dependency** for reads: commit the vault `_brain/_index.json` to the GitHub mirror so `get_index` has an off-Mac source; document degraded capabilities when the Mac sleeps in `surfaces/README.md`. *(A1/E1/L3 · M)*

**Tier 3 — keystone unlock (raises C/F/J/L/B together):**
10. **Build the eval/promote gate** (`capture-nudge.sh:24`, handoff 034): route agent-authored rule/memory edits to a staged commit/branch for human approval before merge; this turns capture from nudge-only into real persistence and enables wiki-grows-from-questions, skill extraction, and self-learning. *(C6/F8/J1/L4/B7 · L)*

**Tier 4 — discipline & hygiene (lower priority):**
11. Split/reconcile the over-broad connectors (`mac-mcp` ~25, `github-mcp` 43 tools) and add per-tool call counters + a periodic frequency report. *(G1/G3 · L/M)*
12. Codify a hard 3–5 iteration cap + an in-repo verify/iterate skill (or ADR keeping verification external). *(I1/F5 · M)*
13. Add a `context/_adhoc.md` + one-area-per-run bleed guard + explicit global-only fallback line in `do.md`; trim `working-style.md` under 300w. *(D2/D5/D6/D8 · S)*
14. Add a lightweight enforced token-budget signal (CI or start-gate) from the `context-budget` logic. *(D11/L5 · M)*

---

## 4. What is genuinely strong (don't regress these)

- **Cost/OSS discipline (K): a clean sweep.** Free/open substrate, zero embeddings, pure-bash heartbeat, every hosted piece on a verified $0 free tier and swappable, deliberate-and-justified redundancy. Both remote connectors live-verified authenticated.
- **Credential portability (A5) & the stateless-processor inversion (A4):** live-verified off-Mac; one SA token resolves everything everywhere.
- **The running half of freshness (B1 light cycle):** confirmed 9 consecutive green nightly runs, Mac-independent, read-only.
- **Single-source skills + clean core/thin-client seam (F1, F2):** the future-sharing seam is genuinely clean.
- **Least-privilege & governance (I3, I4, J2):** real hard gates (force-push blocker, read-only specialists, `contents:read`), draft-over-merge, no runtime self-rewrite, no fine-tuning.
- **Observability from day one (L5):** CI Step Summaries, git history, append-only PROGRESS, 35 sequential handoffs.

## 5. Honest divergences (intentional, not failures)

These are scored 🟡/❌ against the *literal* spec but are deliberate design choices — flagged so they aren't "fixed" by mistake:
- Two-lane (global/project) memory instead of working/episodic/semantic tiers (`memory/README.md`).
- No `agents.md`/manifest/preset-gallery — removed per `decisions/0011 #4` ("subtract rather than complete").
- Supersession **deletes** the old fact (audit via git history) rather than retaining `superseded:true` + retrieval-filtering.
- Writes are **main-only** (force-push-guarded) rather than branch/draft-isolated (`no-force-push-guard.sh:5`).
- Verification delegated to an external `superpowers` skill rather than owned in-repo.
- Module/rule files deliberately leaner than the spec's 200–600w floor.

*If any of these should instead match the spec literally, that's a decision to make explicitly — several would benefit from a one-line ADR so the divergence is recorded rather than implicit.*
