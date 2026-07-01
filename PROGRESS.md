# schnapp-os — execution log

Append one line (one bullet) per step: date, what changed, why. Point to the relevant
handoff/decision/commit for narrative detail instead of inlining it — that detail already
lives there. Newest at the bottom.

Rotates per [decisions/0022](decisions/0022-progress-md-rotation-policy.md): when this file
crosses ~600 lines, the full verbatim snapshot moves to `docs/archive/` and this file is
trimmed back to the still-relevant window. Full history before this reconciliation:
[docs/archive/PROGRESS-archive-2026-06-03-to-2026-06-30.md](docs/archive/PROGRESS-archive-2026-06-03-to-2026-06-30.md).

## Open items carried forward (never closed in the archived range)
- **`#2` repo-flattening** (decisions/0011) — drop the marketplace-plugin packaging
  (`plugins/core/`). Deliberately deferred 2026-06-23; confirmed still not done 2026-06-30.
- **`brain-capture` MCP server prune** — the `76d929ef` test-only note-capture server was
  slated for removal 2026-06-23 when memory-mcp shipped as its replacement; confirmed still
  connected 2026-06-30.

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
