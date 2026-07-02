# schnapp-os — execution log

Append one line (one bullet) per step: date, what changed, why. Point to the relevant
handoff/decision/commit for narrative detail instead of inlining it — that detail already
lives there. Newest at the bottom.

Rotates per [decisions/0022](decisions/0022-progress-md-rotation-policy.md): when this file
crosses ~600 lines, the full verbatim snapshot moves to `docs/archive/` and this file is
trimmed back to the still-relevant window. Full history before this reconciliation:
[docs/archive/PROGRESS-archive-2026-06-03-to-2026-06-30.md](docs/archive/PROGRESS-archive-2026-06-03-to-2026-06-30.md).

## Open items carried forward (never closed in the archived range)
(none - the last one, the `brain-capture` prune, closed as moot 2026-07-01: the `76d929ef`
UUID is the live obsidian-mcp connector, not a dead server; see handoff 052.)

## 2026-06-03 to 2026-06-23 — Parts 0-11 build-out (archived)
Full build of the original 11-Part plan (repo/tracker/sync, global rules, connectors
[op-mcp/obsidian-mcp/memory-mcp], the capability layer, Code hooks, agentic-OS scaffold), the
2026-06-22 SA-token rotation, and the 2026-06-23 plan review that reframed PLAN.md as a backlog
(`decisions/0011`). All Parts closed. Full narrative in the archive linked above.

## 2026-06-26 onward — current era
- 2026-06-26 Vault flatten: 10 secrets consolidated into `web-variables`, all consumers
  repointed, 5 legacy bundles deleted (vault now 27 items). Rotation still owed (flatten
  copied values, didn't rotate them).
- 2026-06-27 Renamed plugin `claude-kit-core` → `schnapp-os-core` (commit `d6e0a51`); owner
  must reinstall to activate.
- 2026-06-27 Agentic-OS loops Phase 1 shipped (provenance detector + CI). See
  `docs/superpowers/plans/2026-06-27-agentic-os-loops.md`, handoff 035.
- 2026-06-29 Wired edit-time security hooks (`secret-scan-on-write.sh`, `shellcheck-on-write.sh`)
  + new `secrets-leak-reviewer` agent.
- 2026-06-29 Doc-currency sweep: fixed 3 stale descriptions (routine count, hook-delivery
  prose); CATALOG regenerated.
- 2026-06-29 Full repo review (`docs/repo-review-2026-06-29.md`); root-caused and fixed the
  dead `bacpac-backup` LaunchAgent (55-day silent gap).
- 2026-06-29 Backup gap fully resolved: real cause was a DB rename (`sports-modeling` →
  `schnapp-bet`) the script hadn't followed; fixed and re-exported (344M, verified).
- 2026-06-29 Worker-auth doc "contradiction" resolved as stale drift, not a real fork;
  `docs/headless-claude-auth.md` is canonical (`ANTHROPIC_API_KEY`).
- 2026-06-29 Switched learning-worker to Claude subscription auth (ADR 0019); root cause was a
  malformed vault token (stray whitespace/quotes), not the API-key path being wrong.
- 2026-06-29 Built `check-infra-health.sh` liveness probe (the silent-stop class), scheduled
  daily 08:30; `brew install unixodbc` fixed the host `sqlcmd`.
- 2026-06-30 Documented `CLAUDE_CODE_OAUTH_TOKEN` re-mint maintenance in `credentials-map.md`
  (expires ~2027-05).
- 2026-06-30 MCP connector reachability audit (5 connectors, all confirmed reachable off-Mac);
  fixed `environment-and-access.md` allowlist, `.mcp.json`, and a `rotate-secret` gotcha.
- 2026-06-30 Portal doc-sync after mac-mcp/github-mcp moved behind the Cloudflare portal
  (ADR 0020); swept 11 docs to match.
- 2026-06-30 Added root `CLAUDE.md` (agent front door, reference-only); captured
  owner-working-preferences #7 (auto commit+push, never leave open PRs).
- 2026-06-30 Sharpened `verify-before-asserting.md` (Read tool vs Bash `cat` — the latter
  doesn't register a file as read); closed all open org PRs (0 open).
- 2026-06-30 Built the `pr-sweep` skill (org-wide open-PR triage).
- 2026-06-30 Session-close hygiene: re-verified 4 stale-flagged memory facts; confirmed backup
  P0 resolved.
- 2026-06-30 Installed the infra-health probe live (`launchctl load`); first run all-green,
  11/11 agents.
- 2026-06-30 Built off-Mac paging (`notify-ops.sh`, ntfy), wired into the infra-health RED
  path; verified end-to-end.
- 2026-06-30 Built the Mac liveness dead-man's-switch (`.github/workflows/mac-liveness.yml`,
  30min cron → GitHub issue + email on down).
- 2026-06-30 Wired granular incident alerting (`ops-alert.sh`); infra-health cadence bumped to
  every 30min; tested RED→open, recovery→close.
- 2026-06-30 Session wrap: hardening pass (notify-ops bug, bash 3.2 empty-array, jq
  sanitization), dropped the iMessage channel (can't self-page). Handoff 039.
- 2026-06-30 Owner enabled the Cloudflare Tunnel Health Alert (event-driven complement to
  mac-liveness).
- 2026-06-30 Substrate-rethink review (`docs/repo-review-2026-06-30-substrate-rethink.md`);
  shipped a P0 batch: fail-closed `mac-mcp` fallback removed, 2 stale-status docs reconciled,
  `scope: global` added to 3 memory facts.
- 2026-06-30 P0 silent-stop hardening: learning-worker incident alerting (RED/GREEN); new
  `render-health.yml` (30min cron on op-mcp + memory-mcp).
- 2026-06-30 Wrote the substrate-rethink assessment doc; verdict surgical not teardown;
  corrected a connectors-agent identification error.
- 2026-06-30 Substrate-rethink follow-through: GitHub MCP parity confirmed (40/43 tools, net
  upgrade); found `brain-watcher` silently dead since 06-22 (surfaced to owner, not auto-loaded).
- 2026-06-30 Step 1: `brain-watcher` restored and verified; added to `EXPECTED_AGENTS` so
  infra-health would have caught it (now 11/11).
- 2026-06-30 Corrected `plugin.json` description (stale `hooks.json` and superseded-ADR claims
  removed).
- 2026-06-30 Session wrap → handoff 040. Steps 1-2 of substrate-rethink done; Step 3
  (Loop→Agent SDK) designed and approved, deferred to a fresh session.
- 2026-06-30 Owner pref: handoffs now delivered as a one-click `spawn_task` chip + file, not
  copy-paste (supersedes owner-working-preferences #6).
- 2026-06-30 Step 3 cutover: learning-worker distillation swapped
  `claude -p --dangerously-skip-permissions` → file-scoped `learning_distill.py` (Agent SDK,
  ADR 0021); subscription auth proven headless first.
- 2026-06-30 Step 3 controlled e2e PASSED (throwaway queue); live worker ran the new path
  end-to-end, `rc=0`.
- 2026-06-30 🔴 fix(security): learning-worker auth line was logging the 1Password SA token
  value; fixed (`005da67`), 1 leaked log line scrubbed. SA rotation recommended; owner declined
  (accepted-risk call, see `credentials-state` memory).
- 2026-06-30 Step 3 fully done and live → handoff 041. Cutover `49f79f6` + security fix
  `005da67` on main, all verification passed. Owner: SA rotation declined, permissions loosened
  to `bypassPermissions`. Next: substrate-rethink P1/P2/P3.
- 2026-06-30 Reconciled `PROGRESS.md` (1281 → ~100 lines): full verbatim snapshot archived to
  `docs/archive/PROGRESS-archive-2026-06-03-to-2026-06-30.md`; live file trimmed to true
  one-liners per the header spec; rotation policy recorded in `decisions/0022`; surfaced 2
  dangling open items (`#2` repo-flattening, `brain-capture` prune) the unreadable length had
  been hiding.
- 2026-06-30 Scoped `#2` repo-flattening: confirmed via `claude-code-guide` that Claude Code
  natively discovers `.claude/{skills,commands,agents}/` with no plugin needed, unblocking the
  06-23 "riskier" deferral. Paused before executing at owner request — folded into a broader
  streamline/simplify brainstorm instead of a standalone migration. Wrote handoffs/042 (full
  scope + context) and a `spawn_task` chip for a fresh Opus 4.8 session.
- 2026-06-30 Streamline brainstorm (session 042+) → refined plan of action. Verified 5-agent
  read-only audit (diagnosis: capture works; enforcement + fragmentation are the disease —
  code/hook fixes stop recurrence, prose does not). Locked design + phased build plan. Key
  decisions: two-repo split on the atomicity line (new PRIVATE `schnapp-vault` = the Obsidian
  vault, moved out of OneDrive; memory lane migrates there); ONE flat CI-enforced memory schema
  (fixes the dead supersede-check + 3-schema drift); enforcement ladder (advisory→memory→hook→CI)
  with recurrence-as-escalation-trigger; flatten the plugin → native `.claude/` (resolves `#2`,
  yes). Spec `docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md` + plan
  `docs/superpowers/plans/2026-06-30-schnapp-os-streamline.md`. Not yet executed.
- 2026-06-30 Wrote handoff 043 (`handoffs/043-execute-phase-1-vault-standup.md`) as the resume
  point for Phase 1 (vault stand-up), execution model = subagent-driven with the orchestrator
  driving; dropped a `spawn_task` chip for a fresh Opus 4.8 session. Design session ends here.
- 2026-07-01 Phase 1 (vault stand-up) EXECUTION START, subagent-driven. Owner resolved the open
  fork → **Fork A**: consolidate to ONE vault repo by repurposing the existing `obsidian-vault`.
  **Task 1 (gate 1) DONE:** deleted the empty `SchnappAPI/schnapp-vault`, renamed
  `obsidian-vault` → `schnapp-vault` (private, 25MB, history+clones preserved), cloned to
  `~/code/schnapp-vault` (git-native, out of OneDrive). Probe-verified current-state map matched
  handoff `dd2ba64` exactly. Re-cut tasks in the plan doc (exec order 1→2→5→3+4→6→7→8→9→10;
  memory stays in schnapp-os until task 8 repoints memory-mcp, then task 9 removes it). Full
  rationale → Phase-1 ADR at task 10.
- 2026-07-01 Phase 1 task 2 DONE (vault `718f9be`): authored the vault contract in
  `schnapp-vault` — `agents.md` (NARROW; the single definition site for the flat memory
  schema, exact §3.5), `index.md` (pointer-index), `README.md` (references agents.md, does
  not restate). Writing-style standard, no em dashes. Single-source anti-drift fix in place.
- 2026-07-01 Phase 1 task 5 DONE (vault `6401757`): `scripts/check-frontmatter.sh` (TDD, 9
  fixtures) — the flat-schema enforcer that FIXES the dead supersede-check. Fails on nested
  `metadata:`, missing any of the 8 flat keys, bad type/area/date/superseded values, name not
  matching filename, and orphan `superseded: true` with no `[[successor]]`. Runs before the
  data it will validate (task 3+4) and before CI wiring (task 6).
- 2026-07-01 Phase 1 tasks 3+4 DONE (vault `167ecaa` + link fix `f402248`): folded all 12
  memory facts from schnapp-os into `schnapp-vault/memory/` and normalized each to the flat
  8-key schema (un-nested `metadata:`, added `created:` from git first-commit dates,
  `area: global`, `superseded: false`; kept the 5 existing `type:` values). `check-frontmatter.sh`
  passes 12/12. Scaffolded `areas/knowledge/reviews` (`.gitkeep`). MEMORY.md index regenerated,
  README slimmed to point at `agents.md`. Fixed 4 cross-repo `../` links (§10) to path-free plain
  text. schnapp-os `memory/` LEFT LIVE (memory-mcp still serves it until task 8 repoint).
- 2026-07-01 Phase 1 task 6 DONE (vault `3137688`): wired `vault-freshness.yml` CI gate — runs
  `check-frontmatter.sh` over `memory/` on push/PR (path-scoped, read-only perms). Real GitHub
  Actions run `28496925200` concluded SUCCESS on the good tree; bad-fact fail-path proven locally.
  The surface-independent enforcement point (spec §3.6) is live. **VAULT BUILD (tasks 1-6) COMPLETE.**
  Next: Gate 2 (OneDrive exit) + Gate 3 (repoint) — owner-confirm.
- 2026-07-01 Phase 1 GATE 2 (task 7) DONE + task 8 local parts DONE, per the verified gate-2 spec
  (`docs/superpowers/plans/2026-07-01-gate-2-onedrive-exit.md`). Owner-confirmed; Obsidian closed for
  the cutover. Repointed all 7 live OneDrive consumers: obsidian-mcp `connectors/obsidian-mcp/server.py`
  (schnapp-os `6ca6bae`, main checkout ff'd so the live symlink target updated), Brain Agent
  `inbox_watcher.py`+`brain_agent.py` → dynamic `parents[2]` (vault `521e6c9`),
  `com.schnapp.brain-watcher.plist` (ProgramArguments+WorkingDirectory), the `~/Documents/Obsidian`
  symlink → `~/code/schnapp-vault`, `obsidian-state` fact superseded (vault `9bd1756`), schnapp-bet
  `CONNECTIONS.md` (`37b07b0`). Stopped→repointed→reloaded both launchd services; brain-watcher logs
  `Watching: ~/code/schnapp-vault/Inbox`, obsidian-mcp up on :8767. vault CI green on the memory edit.
  Sweep = ZERO live OneDrive hardcodes. OneDrive + `~/code/obsidian-vault` left as cold backups
  (nothing deleted). PENDING for Gate 3: memory-mcp Render `MEMORY_REPO`→schnapp-vault (owner) + remove
  `schnapp-os/memory/` (task 9). ADR consolidated at task 10.
- 2026-07-01 Phase 1 GATE 3 (task 8) DONE + VERIFIED: memory-mcp (Render `memory-mcp-rtad`) repointed
  `MEMORY_REPO` `SchnappAPI/schnapp-os` → `SchnappAPI/schnapp-vault` (owner). Fine-grained PAT
  `SCHNAPP_OS_PAT` (Render env `GITHUB_TOKEN`) granted Contents R/W on the private schnapp-vault (was
  schnapp-os-only → "Directory not found" until fixed). `memory_health` = authenticated,
  repo=SchnappAPI/schnapp-vault, 14 files; `memory_read obsidian-state` returns the normalized
  flat-schema fact. ALL 3 gates + all consumers now on the vault. Remaining: task 9 (relocate memory
  procedures + retarget refs + repoint hooks + `git rm schnapp-os/memory/`), task 10 (ADR + trackers).
- 2026-07-01 Phase 1 (task 9) DONE + VERIFIED: schnapp-os no longer owns `memory/`. Relocated the memory
  SYSTEM PROCEDURES (freshness gate, end-of-session write, on-correction routing, dual-altitude promotion)
  to `docs/memory-lane.md` — the canonical schnapp-os-side doc; schema is NOT restated, it references the
  vault `agents.md` "Memory frontmatter schema" (single definition site). Repointed LIVE hooks:
  `session-start-gate.sh` MEM `$REPO/memory` → `$HOME/code/schnapp-vault/memory` + satellite loop
  OneDrive-Obsidian → `~/code/schnapp-vault`; `capture-nudge.sh` + `session-end-backup.sh` comment/output
  refs → `docs/memory-lane.md`; `backup-archive.sh` `OBSIDIAN_VAULT_DIR` default → `~/code/schnapp-vault`.
  `.claude/settings.json` `autoMemoryDirectory` `~/code/schnapp-os/memory` → `~/code/schnapp-vault/memory`
  (+ `$comment` refs). Retargeted README, CLAUDE.md, `session-hygiene`/`learn-route`/`grill-me`/`notes-lookup`
  SKILLs, `scheduled-tasks/memory-consolidation.md`, `connectors/memory-mcp/README.md`+`src/tools.ts`,
  `credentials-map.md`, `surfaces/code-mac.md`, `templates/project-CLAUDE.md`, the 3 check-script comments.
  `git rm -r memory/` (12 facts + MEMORY.md + README.md; canonical copy now in the vault). VERIFIED:
  `session-start-gate.sh` exit 0, its `[memory]` scan now hits the vault's 14 facts (no supersede-orphans,
  no stale) — not a no-op; freshness CI green (CATALOG current); secret scan 0 BLOCK; grep sweep clean of
  LIVE `schnapp-os/memory`/`memory/README.md` refs (only append-only history + a log-path false positive
  remain). PENDING (owner, outside repo): USER-scope `~/.claude/settings.json` `autoMemoryDirectory` →
  `~/code/schnapp-vault/memory` on this + every machine. Next: task 10 (ADR + final trackers).
- 2026-07-01 Phase 1 (task 10) DONE → **PHASE 1 COMPLETE.** Wrote
  [decisions/0023](decisions/0023-two-repo-vault-split-flat-memory-schema.md) (two-repo split on the
  atomicity line, git=one-truth, vault-out-of-OneDrive, Fork-A consolidation, one flat CI-enforced
  memory schema). Set USER-scope `~/.claude/settings.json` `autoMemoryDirectory` → the vault on THIS
  Mac (other machines still owed the one-liner). Deliverable met: `schnapp-vault` private = the
  Obsidian vault at `~/code/schnapp-vault`, 12 facts on one flat schema, `vault-freshness.yml` CI
  green, obsidian-mcp + Brain Agent + memory-mcp all serve the vault, schnapp-os no longer owns
  `memory/`. Tracked follow-up: vault working-tree auto-commit (git truth lags Obsidian edits); prune
  the stale `~/code/obsidian-vault` clone. Next phase: 2 (flatten the plugin) or 4 (context discipline).
- 2026-07-01 Phase 2 T1: flattened plugins/core → native .claude/{skills,commands,agents} + top-level
  rules/scripts/hooks + root CATALOG.md; rewired settings.json hooks, gen-catalog, both CI workflows,
  learning-loop scripts, hooks, tests, plists (c96783b). CI green.
- 2026-07-01 Phase 2 T2: removed .claude-plugin/marketplace.json + plugins/core/.claude-plugin/plugin.json; plugins/ + .claude-plugin/ trees gone — plugin packaging deleted from the repo.
- 2026-07-01 Phase 2 T3: retargeted ~24 live docs (CLAUDE/README/templates/surfaces/scheduled-tasks/docs + moved SKILL/agent/rule internal refs) off plugins/core/ to the native paths; history (handoffs/decisions/PLAN/PROGRESS/archive/prior plans+specs) left as-is.
- 2026-07-01 Phase 2 T3b: repaired 50 move-broken ../-relative links across 20 .claude/ files (T1 git-mv depth shift; invisible to the plugins/core residual gate). broken-link re-scan = 0.
- 2026-07-01 Phase 2 T4: ADR [decisions/0024](decisions/0024-flatten-plugin-native-claude.md) records the flatten (executes 0011 #2); repo work complete (T1-T3b on main). Remaining: per-machine owner gate (~/.claude @import + plugin uninstall + settings + plist reload) then T5 (verify double-load gone + final review + handoff 045).
- 2026-07-01 Phase 2 final review (Opus, whole-branch): fixed 2 more location-derived-root escapees the same class kept hiding (learning-eval.sh default archive path was a silent no-op; test-supersede-orphans repo calc gutted its own coverage) + untracked a stray scripts/*.pyc and added a __pycache__/*.pyc gitignore rule. Class now fully swept (3 total).
- 2026-07-01 Phase 2 COMPLETE (handoff [045](handoffs/045-phase-2-flatten-complete.md)): plugin flattened to native .claude/ + top-level rules/scripts/hooks + root CATALOG; marketplace + plugin.json deleted; ~24 live docs + all executables retargeted; owner gate done on this Mac (plugin uninstalled, ~/.claude @import → rules/global/, plists re-rendered). Double-load GONE, hooks fire from the flattened layout, CI green on all 5 commits. ADR 0024. Other machines owe the one-time per-machine gate. Next: Phase 4 (recommended) / 3 / 5.
- 2026-07-01 Phase 4 T1: authored rules/global/writing-style.md (instruction-file writing standard, previously only referenced); de-duped working-style.md's writing mechanics into it; wired the @import into templates/user-global-CLAUDE.md (7->8); CATALOG regenerated. Other machines owe the one-line ~/.claude @import.
- 2026-07-01 Phase 4 T2: retired PLAN.md (677 lines, 11-Part build all closed) to a thin pointer + verbatim archive (docs/archive/PLAN-archive-2026-07-01.md); ADR 0025; retargeted CLAUDE.md/README/framework off PLAN.md as the status source. No active work lost (open threads verified closed/tracked-elsewhere).
- 2026-07-01 Phase 4 T3: added hooks/length-advisory.sh (PostToolUse WARN/exit-0 when an always-load or rules file exceeds its heuristic line limit; 50 global / 120 modules+CLAUDE); TDD test + CI self-test; wired settings.json; CATALOG regenerated.
- 2026-07-01 Phase 4 T4: added a generated + CI-gated handoff index (scripts/gen-handoff-index.sh -> handoffs/README.md, newest-first, resume-point marked); gated in check-freshness.sh like CATALOG. Files stay in place (30 path cross-refs); no move.
- 2026-07-01 Phase 4 final review (Opus): fixed the PLAN.md-retirement stale-reference class T2's retarget missed. Group 1: anti-stale.md (always-load) + always-loaded-instructions + grill-me stopped commanding "flip the PLAN.md box" (-> per-initiative plan-doc box), matching ADR 0025. Group 2: CLAUDE.md + README "7"->"8" global rules. Group 3: dropped ~29 stale PLAN.md/Part-N provenance locators across scripts/config/docs; CATALOG regenerated. Second pass (9ceb382): cleared the remaining Part-N stragglers + README/surfaces content still describing the removed marketplace plugin as current (Phase-2 fallout invisible to the plugins/core grep).
- 2026-07-01 Phase 4 COMPLETE (handoff [046](handoffs/046-phase-4-context-discipline-complete.md)): writing-style rule global (8 rules), PLAN.md retired to a pointer + archive (ADR 0025), length-advisory hook live, handoff index generated + gated. CI green throughout; stale-reference class swept. Streamline Phases 1/2/4 done; next = Phase 3 (enforcement gates), then 5 (Cowork). Other machines owe the writing-style @import one-liner.
- 2026-07-01 Phase 3 T1: added scripts/check-secret-bytes.sh (byte-check gate for stored secrets: whitespace/wrapping-quote/truncation/prefix, never prints the value); TDD 9 cases incl. a value-leak guard; CI self-test; rotate-secret Verify step now byte-checks. Gates the malformed-secret class (spec 4.3, ADR 0019).
- 2026-07-01 Phase 3 T1 adversarial review (security): fixed a Critical value-leak (inherited SHELLOPTS=xtrace traced the secret to stderr; now unset+set+x at top) and fail-open bypasses (non-numeric --min-len, NBSP/U+2028 whitespace, single-sided quotes, prefix-only value); +regression tests. Gate now fails closed. All 5 attacks re-verified closed by the controller. Commit ec08400, CI green.
- 2026-07-01 Phase 3 T1 SHIPPED; handoff [047](handoffs/047-phase-3-t1-secret-gate-done.md). Boundary drawn here: T2 (rewire the autonomous self-editing loop so recurrence drafts a gate) is design-heavy + high-stakes, handed off for fresh context, with T3 (last-verified) + T4 (ADR 0026). Streamline 1/2/4 done + Phase 3 T1 done.
- 2026-07-01 Phase 3 T2: rewired the nightly learning loop — new scripts/learning-recurrence.sh counts error-class recurrence (deterministic signature over archive+queue) and drafts a GATE as a GitHub issue (owner approval) instead of prose; a class is marked drafted + held from distillation ONLY when its issue actually files (gh-fail -> prose fallback + retry, no orphaning); NEVER auto-lands (learning-gate.sh byte-unchanged; auto-land scope stays .md under rules/memory). TDD 28 (recurrence) + 14 (worker) + 16 (live-path gh-shim harness); spec review Approved, adversarial review HOLD -> fixed (A1 orphaning + A2/S1/S2 Minors). Commits a9acefc + e419fbc. CI green.
- 2026-07-01 Phase 3 T3: extended last-verified coverage — added frontmatter to credentials-map.md (source .env.template) + connectors/{github-mcp,mac-mcp,obsidian-mcp}/README.md (source that dir's server.py); check-freshness passes today, a deliberately-stale fixture proven to FAIL (exit 1, STALE named the doc) then removed. Independent review folded into the Phase-3 final whole-branch pass.
- 2026-07-01 Phase 3 T4 + COMPLETE: ADR decisions/0026 (enforcement ladder advisory/memory/hook/CI + recurrence-escalation policy); Phase 3 final whole-branch review (opus) READY-TO-CLOSE (cardinal no-auto-land invariant proven end-to-end, ADR accurate, trackers consistent); em dashes stripped from 0026 per writing-style. Handoff 048. Streamline Phases 1/2/3/4 done; only Phase 5 (Cowork) remains.
- 2026-07-01 Em-dash sweep (Opus): stripped U+2014 from every live instruction file (rules, CLAUDE.md, .claude/{skills,commands,agents} + settings.json $comment, templates, surfaces, README, PLAN, credentials-map) per writing-style.md. 285 dashes across 46 files: colon for label:definition, spaced hyphen for asides, 8 line-spanning cases restructured; frontmatter kept to hyphen (YAML-safe, not colon). Also de-dashed gen-catalog.sh emit strings so a regenerated CATALOG is clean. Left frozen history (decisions/handoffs/PROGRESS/archive), AUDIT.md (dated point-in-time report), and script code-comments. Verify: git grep U+2014 = 0 on scope; freshness + ci-lint green.
- 2026-07-01 Em-dash class CLOSED (Fable): finished the sweep repo-wide (502 more across 81 files: live docs, scheduled-tasks, connectors, scripts/hooks/workflow comments and messages, configs) and wired enforcement per the ADR 0026 ladder (deterministic + recurred): new scripts/check-writing-style.sh (frozen-history exempt: decisions/handoffs/archive/PROGRESS/AUDIT + dated snapshot reports + T3 leave-list; vault index-line format skipped) gates CI via ci-lint.yml, hooks/em-dash-on-write.sh guards at write time, self-test in freshness.yml. Rode along per fix-what-you-find: deleted the dead memory-frontmatter CI step + script + test (vault CI owns the schema since the lane moved), fixed the stale repo-local memory/ path class (10 files -> vault refs), the stale obsidian-vault repo-name class (6 files -> schnapp-vault), completed CLAUDE.md's hook list, dropped memory from backup-archive's mirror loop, hook line-2 format + gen-catalog parser moved off the em-dash separator, CATALOG + handoffs/README regenerated. Full test suite green (learning-worker false-fail was pre-commit dirty-tree only). Judgment call recorded: AUDIT.md stays put frozen (dated snapshot, plan T3 precedent) rather than archived. Follow-ups chipped: learning loop still routes durable facts to gone repo-local memory/ (needs vault-lane design), Phase 5 Cowork.
- 2026-07-01 Phase 5 repo-side COMPLETE (T2 [x]; T1/T3/T4 [~] pending owner Cowork legs): handoff-packet convention canonical in docs/memory-lane.md (write-on-stop = end-of-session write incl. working-memory + newest handoff + indexes, BOTH repos pushed; read-on-start = freshness gate); session-hygiene carries the hookless transport (connector read-modify-write, byte-exact handoffs/README emulation, CI-diff-verified); surfaces/cowork.md rewritten (dead plugin-install path dropped per 0024; T1 verify + T3 probe scripted in enablement); ADR decisions/0027 (packet over git; sanctioned index emulation; memory-mcp = optional upgrade). T1 finding: github-mcp rides all-repos GITHUB_PAT, so schnapp-vault already in scope - the owner leg is verify-only. De-staled in passing: credentials-map SCHNAPP_OS_PAT scope (+vault), code-mac/code-work-machines hook delivery (plugin-wide -> .claude/settings.json). Handoff 049 = the Code-stop leg of the T4 round-trip AND the owner runbook; plan closes on the return leg. Fixed in passing (found live): check-writing-style.sh FILE-mode false-flagged FROZEN history when handed an absolute path from another checkout (worktree-session hook vs main-checkout file: prefix-strip no-oped, is_frozen never matched, and the hook told the agent to edit append-only PROGRESS.md); now maps such paths to their own repo-relative form before the frozen match, untracked fallback stays checked-live; +2 regression cases (suite 6/6).
- 2026-07-01 Learning-loop fact routing FIXED (ADR [0028](decisions/0028-learning-loop-vault-fact-routing.md); renumbered from 0027 on rebase: the Cowork session landed decisions/0027 first): durable facts now land in the VAULT lane via a worker-owned automation clone (distill prompt + SDK add_dirs -> <clone>/memory/ per the vault schema, fail-fast exit 4 if the clone is missing; worker preps the clone before distillation, gates the fact leg in-clone with scope memory/*.md + the clone's own check-frontmatter.sh, pushes the vault's main, best-effort ff-pull of the clean live tree only). learning-gate.sh scope is now an argument with default rules/*.md, so a repo-local memory/ write HOLDs -> review issue (the wrong-repo auto-land is closed); provenance also exempts no-frontmatter index files and HOLDs updated:-removal (old bypass). TDD: gate 28, distill 6 (new), vault-live 29 (new gh-shim harness: land/hold/bad-schema/wrong-repo/prep-fail), recurrence-live 16, worker 14; wired into freshness.yml. Closes the em-dash-session chip.
- 2026-07-01 Ride-along find while verifying ADR 0028: the LIVE vault lane failed its own schema checker (owner-working-preferences.md still nested metadata:, old schema; would have held every nightly fact + gone red in vault CI on the next memory push). Migrated flat in the vault (cd892a1; the first attempt dc13cb2 was intercepted: the harness auto-memory layer re-nested the in-session Edit within seconds, evidence recorded in ADR 0028 "Rejected"). Vault lane checker-clean again; the standing harness-nested vs vault-flat schema contract conflict is chipped as its own designed task (spawn_task 2026-07-01).
- 2026-07-01 ADR 0028 adversarial review (pre-push): 1 Critical CONFIRMED end-to-end (schema-less fact in a memory/ SUBDIR auto-landed on a test vault main: scope case-glob crosses '/', vault checker scanned only direct children) -> closed 3 ways (worker flat-lane depth check holds any non-direct-child fact; vault check-frontmatter.sh made recursive, vault commit 81df3b8; harness regression case). Empty-scope finding was worse than reported: '${2:-}' substituted the rules default for an EXPLICITLY empty scope (fail open) -> now '${2-}' + in_scope matches nothing (fail closed). Also hardened per its residual list: vault clone dir inside the repo aborts; prep self-heals (checkout -f); live-tree ff-pull requires clean AND on-main. Suites after fixes: gate 30, vault-live 37, all 16 suites green; style + freshness green.
- 2026-07-01 CI red on a5707b6 (freshness, vault-live case 1 only) root-caused as git default-branch skew: bare-origin fixtures inited without -b main leave HEAD on the host default (master on ubuntu), so fresh clones check out an unborn branch; the Mac's git guessed the sole branch, CI's did not. Fixed the class: -b main on every bare init in both live harnesses, worker's fresh-clone prep pins checkout -qf main (never trusts remote HEAD), dead probe line dropped. Proven locally under GIT_CONFIG_SYSTEM init.defaultBranch=master (vault-live 37, recurrence-live 16 green); ci-lint was already green.
- 2026-07-01 freshness red #2 on 1d7445e (same case, 2 remaining fails) root-caused as commit-identity skew: the worker commits inside the clone IT creates, which has no user ident on a CI runner ('(none)' domain refusal) while Mac git auto-derives from the FQDN; the leg degraded into a no-changes HOLD (also masking hold-reason assertions in the held cases). Reproduced exactly with GIT_CONFIG_SYSTEM user.useConfigOnly=true; fixed with an explicit bot ident on the fact-leg commit (-c user.name=learning-worker -c user.email=learning-worker@schnapp.bet, host-independent). Strict-config run now green (vault-live 37, recurrence-live 16); full suite green.
- 2026-07-01 Vault memory-lane schema conflict SETTLED (ADR [0029](decisions/0029-vault-flat-schema-harness-writer-containment.md); the 0028 Follow-up chip): flat stays canonical, harness auto-memory nested writer CONTAINED vault-side. Measured first (Write+Edit both intercepted in ~2s, key-preserving, no at-rest heal, format undocumented + no disable knob, shell writes bypass; headless scratch probe abandoned, child claude -p cannot reach host OAuth). Shipped in vault 6c97b11 (CI green): TDD flatten-frontmatter.sh (11 cases, fail-closed, byte-idempotent) + git pre-commit hook (5 live scratch-repo cases; flattens staged facts, blocks subdir/bad-schema; hooksPath bootstrapped on this Mac) + vault-freshness self-tests all 3 script specs; agents.md gains the "Second writer" section (schema unchanged); interception memory fact superseded in place. autoMemoryDirectory STAYS on the lane (recall preserved); rejected nested-canonical (undocumented version-coupled format, breaks memory-mcp) and moving the dir (kills recall or mirrors the lane). memory-lane.md points at the vault section.
- 2026-07-01 Session-consolidation sweep (found while auditing open sessions): fixed backup-archive.sh to PRUNE the abandoned claude-archive memory/ mirror. The memory lane moved to the vault (ADR 0023) and the script stopped mirroring it, but earlier copies lingered in both OneDrive + vault mirrors and regenerated every run (vault rsync re-copied them from OneDrive), permanently dirtying the vault tree. Now rm the source copy before the vault rsync so --delete clears it downstream. Also fixed a pre-existing SC2001 in the same file. Vault mirror regenerated clean (fossil gone).
- 2026-07-01 Phase 5 Cowork leg DONE (handoff [050](handoffs/050-cowork-leg-round-trip.md)): T1 VERIFIED from Cowork (read vault MEMORY.md + wrote memory/cowork-vault-write-verified.md via github-mcp, flat 8-key schema, vault CI green) + T3 REACHABLE (memory_health authenticated on SchnappAPI/schnapp-vault, memory_list 14 facts; memory_* writes = the memory-leg front line per 0027). Plan T1/T3 flipped [x]; handoff index emulated (050 = resume point). T4 awaits the Code return leg: verify nothing lost, close the plan.
- 2026-07-01 Phase 5 COMPLETE; streamline plan CLOSED (handoff [051](handoffs/051-phase-5-round-trip-closed.md)): the Code return leg verified the round-trip lost nothing - handoff 050 + its emulated index line byte-identical to a fresh `gen-handoff-index.sh` regen, check-freshness + check-writing-style green, vault fact `cowork-vault-write-verified` + MEMORY.md line landed with vault-freshness CI green on both commits (8973634 fact run 28563359296, b845a7d index run 28563381381), PROGRESS line + plan T1/T3 flips present. Phase-5 Done-when MET (Code→Cowork→Code preserves state end-to-end); T4 flipped [x]; all 5 streamline phases closed.
- 2026-07-01 Streamline leftovers CLOSED + full plan audit GREEN (handoff [052](handoffs/052-streamline-closeout-audit.md)): owner-item #4 closed as already-absent (live claude.ai connector list inspected + owner-confirmed: no brain-capture, standalones gone per ADR 0020); Phase-3B client legs closed and superseded in place in vault credentials-state (6b61521: portal legs live-verified via mac-mcp/github-mcp calls, Copilot leg moot - no Copilot MCP client exists; stale "pending" index line + dead plugins/core link fixed). Every Verify across all 5 phases re-run against the current tree: all PASS (per-phase evidence in handoff 052); standing gates green (freshness, writing-style, newest CI on both repos incl. this session's vault push); hygiene verified (no worktrees/branches, both repos clean+pushed, zero org-wide open PRs). Flagged owner-only: plaintext sk-ant-oat01 textClipping on the Desktop (rm command in handoff).
- 2026-07-01 Correction to the item-#4 close (owner question "wasn't brain-capture integrated into the portal?"): closed as MOOT, not as already-pruned. The `76d929ef` connector recorded as "dead brain-capture" is the LIVE obsidian-mcp connector (same 7 tools as connectors/obsidian-mcp/server.py; get_index probed live, serves the brain-agent index); handoff 042's "no repo source, no tool reaches it" was wrong. Never portal-fronted: portal = op/memory/mac/github (ADR 0020), obsidian-mcp stays separate native-OAuth; memory-mcp superseded only its memory-capture role. Plan #4 + handoff 052 corrected; PROGRESS carried-forward open-items block now empty.
- 2026-07-02 Vault auto-commit SHIPPED (the last Phase-1 follow-up): `scripts/vault-autocommit.sh` (main-only, 120s quiet-window debounce, vault pre-commit schema gate honored, rebase-pull before push; exit codes surface commit-block vs push-fail) + launchd `com.schnapp.vault-autocommit` (5-min interval, rendered + loaded live) + infra-health EXPECTED_AGENTS + freshness.yml self-test. TDD 12/12 (scratch bare-origin harness; bash-3.2 mapfile gotcha fixed). Live E2E: canary swept to origin by the agent both directions (vault 6128714 add, 858c55e delete). Ride-along security: com.schnapp.syncrepos.plist held the live GH_PAT plaintext - scrubbed to runtime op read (credentials-map changelog), value transited this transcript (accepted-envelope class, rotation = owner call).
- 2026-07-02 Standing reply rules wired machine-wide: new hooks/standing-rules.sh (UserPromptSubmit, advisory exit-0) injects the owner's no-sycophancy + terse rules into EVERY message across all projects via user-scope ~/.claude/settings.json; durable rule home = working-style.md (new no-sycophancy bullet, hook kept in sync). Other machines owe the one-time settings.json wire (handoff).
