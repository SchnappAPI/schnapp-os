---
name: os-failure-archaeology
description: Use before re-investigating anything that smells already-fought in schnapp-os - "why is this a rule", "was this tried before", "should we package this as a plugin", "why no branches", "why is the vault a separate repo", "a leaked credential note says rotate", "an audit subagent found X" - or before rotating a token, re-flagging an accepted risk, or restarting the mac connector, to check whether that battle is settled. The chronicle of every major incident, dead end, rejected alternative, and reversal - symptom, root cause, evidence path, and whether it is SETTLED, OWNER-ACCEPTED, or STILL-OPEN - so no session re-fights a settled battle or re-flags an accepted risk. For a LIVE symptom (a 401 right now, red CI, a misdelivered response) triage via os-debugging-playbook first.
---

# os-failure-archaeology

The battle map. Every entry below was a real investigation with a recorded outcome. Before you
diagnose, propose, or "fix" something in this repo, check whether it is already here: the most
expensive failure mode in this system's history is re-fighting a settled battle (re-rotating an
accepted credential, re-proposing plugin packaging, re-flagging a closed leak).

Status legend:

| Status | Meaning | Your move |
|---|---|---|
| SETTLED | Root-caused, fixed or decided, evidence recorded | Do not reopen. Reversal requires a NEW ADR (never edit or `git revert`; see `decisions/README.md`) |
| OWNER-ACCEPTED | Known risk, owner explicitly chose to live with it | Do not re-flag unless the stated re-open condition trips |
| STILL-OPEN | Known, bounded, not resolved | Act only with the recorded evidence trail; do not restart from zero |

Jargon used once: ADR = one append-only decision file `decisions/NNNN-*.md`. Vault =
`/Users/schnapp/code/schnapp-vault` (sibling repo holding the memory lane; path = this machine's
clone, other machines clone under `~/code`). Portal = the Cloudflare-managed MCP gateway at
mcp.schnapp.bet fronting the Mac connectors.

## 1. Credentials and secrets

### 2026-06-17 full credential leak: OWNER-ACCEPTED, CLOSED
- **Symptom**: plaintext dump of ALL vault secrets found in private Claude-export files
  (schnapp-vault and the old obsidian-vault).
- **Outcome**: SA token + 3 MCP bearers rotated; residual risk on the rest OWNER-ACCEPTED
  2026-06-27. Exports later retro-redacted anyway (2026-07-15 sweep, 98 files, all six repos scan
  clean; PROGRESS.md 2026-07-15 entry).
- **Re-open condition** (the only one): a repo goes public or a third party gains access.
- **Evidence**: `docs/credentials-archaeology-2026-06-17.md` (history);
  vault `memory/credential-leak-2026-06-17.md` and `memory/credentials-state.md` (current ledger).
- **Corollary rule**: an open exposure lives ONLY in the vault ledger; any "exposed / needs
  rotation" line elsewhere is a defect to DELETE on sight (`rules/global/anti-stale.md`,
  enforced by `scripts/scan-stale-notes.sh` in CI).

### Malformed stored secret 401: SETTLED (ADR 0019)
- **Symptom**: valid subscription OAuth token returned `401 Invalid bearer token`; misdiagnosed
  for days as a CLI v2.1.112 regression, prompting a wrong switch to metered API billing.
- **Root cause**: the vault value was saved with a leading space + wrapping single quotes
  (111 bytes raw vs 108 clean) and sent verbatim.
- **Lesson (institutionalized)**: a mysterious 401 on a stored secret means check raw bytes FIRST
  (`op read <ref> | head -c4 | xxd -p`), never blame the tool or rotate reflexively.
- **Evidence**: `decisions/0019-learning-worker-subscription-auth.md`; vault
  `memory/malformed-stored-secret-401.md`. Related: the OAuth token expires ~2027-05; re-mint via
  `claude setup-token`, store with no whitespace or quotes (as of 2026-07-17).

### op-wrap quote bug: SETTLED
- **Symptom**: all 6 launchd services crash-looped 2026-06-22 with `unrecognized auth type`.
- **Root cause**: `op-wrap.sh` greps the SA-token line from `~/.zshrc` literally (no shell
  sourcing), so quote/whitespace chars on the line shipped into the token. The wrapper has since
  been hardened to strip one pair of surrounding DOUBLE quotes; single quotes or inner whitespace
  still break. Safest form stays fully unquoted (detail: `os-build-and-env` §1.4).
- **Evidence**: vault `memory/op-wrap-token-unquoted.md` (predates the double-quote stripping;
  needs superseding in the vault).

### SA token printed to a log: SETTLED, rotation OWNER-DECLINED
- **Root cause**: `OP_SA:${VAR:+set}${VAR:-UNSET}`: the `:-UNSET` arm substitutes the VALUE when
  set. Fixed in commit `005da67`; leaked line scrubbed; owner declined rotation (PROGRESS.md
  2026-06-30 entry). Do not re-flag.

## 2. Packaging and delivery dead ends

### Plugin / marketplace / gallery era: SETTLED, rejected TWICE
- **Round 1**: the repo was its own marketplace + `plugins/core/` plugin (ADRs 0003-0007 era).
  ADR 0011 (2026-06-23) re-decided ten choices deliberately: plainer repo, no marketplace
  packaging, no module gallery / presets / symlink composer (0011 #4), loops before features,
  subtract over complete. ADR 0024 executed the flatten; the recurring stale-plugin-pin class
  (old snapshot re-firing old hooks, vault `memory/plugin-registry-snapshot-gotchas.md`) was
  DELETED by removing its cause, not gated.
- **Round 2**: ADR 0033 (2026-07-03) re-tested plugin delivery live on CLI 2.1.112 for the
  portable shell: plugin install ALWAYS snapshots to a cache, even from a local directory source;
  live-read plugin delivery does not exist; plugins cannot set `autoMemoryDirectory` or deliver
  rules context. Result: the shell is native user-scope wiring (symlinks + `@import` + absolute-path
  hooks) over the live clones.
- **Your move**: never propose plugin/marketplace packaging for this system again without new
  upstream evidence that snapshot semantics changed. Evidence: `decisions/0011`, `0024`, `0033`.

### Synced distilled rules copy for hookless surfaces: SETTLED, rejected
- claude.ai / iPhone / Cowork read `rules/global/` LIVE via the portal connector
  (probe-confirmed 2026-07-07). A maintained distilled copy was rejected: it is a staleness
  machine (a small line diff can flip meaning). What remains is a pasted bootstrap floor as
  fallback plus connector-health monitoring. Evidence: vault
  `memory/surfaces-live-read-default.md`.

## 3. Trackers and docs

- **PLAN.md retired to a pointer**: SETTLED (ADR 0025). The 11-Part build spine finished, then
  rotted (677 stale lines). Live planning = `docs/superpowers/plans/`; status = `PROGRESS.md`.
  Same shape as the PROGRESS.md rotation policy (ADR 0022).
- **Frozen history is not a todo list**: SETTLED. `AUDIT.md`, `docs/archive/`, and the four
  2026-06-27 loops plan docs (59 unflipped boxes on shipped work, closed with retroactive banners
  in handoff 057) are history. Do not "finish" their unchecked boxes.
- **The no-handoff gap**: SETTLED mechanism, recurrence-prone behavior. 24 commits / ~8 sessions
  (2026-07-04..07-12) landed with no handoff: the 057 audit's top recurring failure. Counter:
  session-start gate warns on tracker drift. A post-058 gap existed again as of 2026-07-13..16
  (STILL-OPEN: check whether the newest `handoffs/` file covers recent PROGRESS.md entries before
  trusting it as the resume point).
- **The decision doc was itself a freshness casualty**: the founding 2026-06-23 decision record
  existed only in an unpulled remote commit while local pull was failing (ADR 0011 live findings).
  Origin story of the freshness gate.

## 4. Vault and memory lane

- **Vault split out of schnapp-os AND out of OneDrive**: SETTLED (ADR 0023). Split on the
  atomicity line (what must commit atomically with a system change stays here). OneDrive was
  dropped because a git working tree under a cloud-sync engine corrupts (`two sync engines race
  .git/`); canonical vault is git-native at `~/code/schnapp-vault`, `~/Documents/Obsidian` is a
  symlink, the OneDrive copy is an inert cold backup. The Obsidian stdio server rejects the
  symlink path: point it at the real path (vault `memory/obsidian-state.md`).
- **Harness re-serializes memory writes**: SETTLED, contained (ADR 0029). Edit/Write-tool writes
  into the vault memory dir get rewritten to a nested schema within ~2s. Containment: vault
  pre-commit flattener + CI; byte-exact writes go via shell redirect (`cat >`), never Edit/Write.
- **memory-mcp write path corrupted frontmatter on every write**: SETTLED. Found in the 057 memory
  pass (reset `created:`, auto-summarized `description:`, invalid YAML, non-schema keys, plus a
  502-induced duplicate index line). Server fixed and verified live on Render (commit `d9a4a17`,
  2026-07-13, as of 2026-07-17).
- **Two writers on `_brain/`**: SETTLED. `com.schnapp.brain-watcher` and vault CI both committed
  `_brain/`, causing rebase conflicts; resolved 2026-07-02 by making vault CI the SOLE processor
  and RETIRING the local watcher (PROGRESS.md 2026-07-02 entry). Do not resurrect the watcher.
- **Dead supersede-orphan check**: SETTLED. The old check grepped a top-level key the nested
  schema had indented, so it matched zero files for its whole life (ADR 0023 context). Lesson:
  a gate that never fires is a gate to distrust; prove a check can FAIL.

## 5. Connectors and infrastructure

- **:8765 restart bind race**: SETTLED (ADR 0010). `launchctl kickstart -k` SIGKILLs, the fresh
  process races the lingering socket, ~2 min crash-throttle loop. Restart with
  `launchctl kill TERM gui/$(id -u)/<label>`; servers also bind with SO_REUSEADDR/SO_REUSEPORT.
  Never `kickstart -k`.
- **Hand-rolled obsidian-mcp OAuth**: SETTLED (ADR 0009). Consent routes attached via the private
  `mcp._custom_routes` attribute were silently ignored by mcp 1.27.2 (it reads
  `_custom_starlette_routes` via the `custom_route()` decorator only): token exchange 404'd
  forever. Lesson: framework-supported APIs only, private attributes are not an interface.
  The whole OAuth machinery was removed 2026-07-18 (P3 bearer swap): obsidian-mcp now uses the
  fleet's static-bearer pattern, so this failure class no longer has a surface.
- **1Password SDK on Cloudflare Workers**: SETTLED (ADR 0004). `@1password/sdk` is Node-only;
  a plain Worker cannot run it. That is why op-mcp lives on Render.
- **mac-mcp portal misdelivery**: STILL-OPEN, detection-only (ADR 0034). One 2026-07-16
  `shell_exec` returned another command's stdout. The origin server was ruled out; the cause sits
  in the Cloudflare-managed portal/tunnel layer, which is unpatchable from here. Mitigation: every
  opaque-output tool echoes the caller's command + `call_id` + `ts`, timeouts clamped to 90s
  (the edge's exact deadline was never independently measured). If a mismatch recurs, the echo
  plus the `mcp.err.log` ledger on the Mac is the evidence to escalate with. Callers: compare the
  echo to what you sent before trusting output.
- **SQL bacpac backup silently dead ~55 days**: SETTLED (handoffs 038/039,
  `docs/repo-review-2026-06-29.md`). Root cause: DB renamed `sports-modeling` to `schnapp-bet`
  and the backup script did not follow. This incident spawned the whole silent-stop stack:
  infra-health probe, mac-liveness dead-man's-switch, auto-closing GitHub-issue alerting.
- **iMessage alerting**: SETTLED, dropped (handoff 039). Self-sent iMessages never notify
  (Apple limitation), so they cannot page. Paging = GitHub issue to email + GitHub mobile push.
- **Render free-tier sleep**: SETTLED. Unmonitored cold-start gap closed by `render-health.yml`
  (30-min cron) doubling as keep-warm (`docs/repo-review-2026-06-30-substrate-rethink.md`).
  First call after idle can still take ~50s (vault `memory/environment-access.md`).
- **Cloud env tools silently absent**: SETTLED. Cause is the environment network allowlist
  (missing `mac-mcp.schnapp.bet` makes the proxy 403 CONNECT), not connector config. ADR 0018;
  vault `memory/mac-cloud-access.md`.

## 6. CI and gate fragility (the gate broke more often than the code)

- **mawk vs BSD awk**: SETTLED. First CI run of the catalog gate failed because `gen-catalog.sh`
  emitted `…` via an awk hex escape mawk does not interpret; fixed by passing the literal bytes
  (comment at `scripts/gen-catalog.sh:50`). Lesson: the Linux runner's awk is not your Mac's awk.
- **Freshness gate false-STALE from git-excluded worktrees**: SETTLED (commit `410e819`,
  PROGRESS.md 2026-07-16 entry). The gate's filesystem walk descended into `.claude/worktrees/*`
  (nested checkouts of old commits), producing local-only false STALEs that "trained everyone to
  ignore it": the worst state for a gate. Fix: enumerate git-TRACKED `*.md` only. The 2 orphan
  worktrees themselves were deliberately left (live-session risk): STILL-OPEN, prune per vault
  `memory/session-worktree-orphan-cleanup.md` when no session references them.
- **16+ hour unbounded CI watch loop**: SETTLED class fix. An
  `until gh run list ...; sleep 20` watcher ran 16+ hours because the commit had ZERO workflow
  runs, so its condition could never be met. Rule: every watch loop bounds itself (timeout or max
  iterations) AND first verifies the awaited thing exists. Same fact file records the sibling
  gotcha: `kill` inside a bash for-loop is silently sandbox-blocked (reports success, process
  survives); issue one direct top-level `kill -TERM pid pid ...`.

## 7. Learning loop

- **Raw `claude -p --dangerously-skip-permissions` distiller**: SETTLED, replaced (ADR 0021).
  Unbounded turns + ALL tools was the wrong shape; rebuilt on the Agent SDK with a bounded tool
  set (no Bash) and a deterministic auto-land gate (`learning-gate.sh`, ADR 0026 recurrence
  ladder). The auth half of the saga is ADR 0019 above.
- **Self-capture pollution**: SETTLED (handoff 054, PROGRESS.md 2026-07-03 T1). An audit agent's
  task-notification QUOTING the correction regex enqueued itself; 6 of 10 archive entries were
  machine-generated, including a recursive queue-echo class. The gate held (distiller no-op'd
  them) but signatures were polluted. Fix: capture guards (skip harness-generated prompts,
  queue-echo shapes, >2000-char pastes), enqueue extracted prompt text only.

## 8. Process and verification failures

- **Subagent audit claims disproved live**: SETTLED lesson (handoff 054). Two of four audit
  findings were WRONG ("3 LaunchAgents not loaded": misread `launchctl list`, all were firing;
  "infra-health misses agents": already listed). Standing rule: verify every subagent finding
  live before acting on it. (Handoff 057's audits were run under this rule.)
- **Same-day reversal on Mac shell access**: SETTLED. ADR 0013 (no standing cloud-agent shell
  access to the Mac) was deliberately re-decided the same day by ADR 0014 (transport-bearer
  standing access): the owner rejected relay-through-a-terminal as not the OS they want. 0014
  governs. Cited here as the model for how reversals happen: a new ADR, never an edit.
- **mac-mcp `write_file` truncation class**: SETTLED gotcha. `write_file` OVERWRITES (no append
  mode); append via `shell_exec` with `cat >>`. `shell_exec` strips the 1Password identity: use
  `op_run` for secrets. Vault `memory/mac-connector-tooling.md`.

## Open threads register (as of 2026-07-17)

STILL-OPEN items with an evidence trail. Do not restart these from zero; do not silently close them.

| Thread | State | Trail |
|---|---|---|
| Web user-scope wiring honored? | ADR 0033's one open empirical question: owner pastes `shell/web-setup.sh`, first web session verifies | `decisions/0033`, handoff 057 open questions (branch knob, vault access) |
| Substrate P2 (GitHub official-MCP swap) | Greenlight-ready, unexecuted since ~2026-07-03: execute or write the killing ADR. P3 (Obsidian bearer swap) EXECUTED 2026-07-18 - only the portal-slot owner add remains | handoff 057 next steps |
| Meta-freeze object-work week | The 057 audit's single highest-payoff change, owner-level, unexecuted | handoff 057 decisions |
| Portal misdelivery root cause | Detection-only; unpatchable layer | ADR 0034 |
| Orphan worktrees + merged local `claude/*` branches | Deliberately unpruned | PROGRESS.md 2026-07-16; vault `memory/session-worktree-orphan-cleanup.md` |
| Post-058 handoff gap | PROGRESS.md ahead of the newest handoff | compare `ls handoffs/ | tail` vs PROGRESS.md tail |

## When NOT to use this skill

- Diagnosing a LIVE failure right now: `os-debugging-playbook` (this skill tells you whether the
  battle was already fought; that one tells you how to fight it).
- How to land a change (main-only, same-commit tracker, gates): `os-change-control`.
- What the system IS today: `agentic-os-reference` and `os-architecture-contract` (this file is
  history; never cite it for current state).
- Whole-system health right now: the `status` skill. Current-surface capabilities: `surface-check`.
- Secret lifecycle actions: `rotate-secret`, `cleanse-secrets`, `vault-resolve`.
- Routing a fresh lesson into the system: `learn-route` (and add the incident HERE only if it was
  a genuine investigation with a settled outcome).

## Adding an entry (keep the chronicle honest)

An entry earns a place only when an investigation reached a recorded outcome (ADR, handoff,
PROGRESS entry, or vault fact). Format: symptom, root cause, evidence path, status. Reference the
canonical record; never restate its detail (`rules/global/anti-stale.md`). Never edit a past
entry's outcome: a reversal is a new ADR plus a status flip here in the same commit.

## Provenance and maintenance

All claims verified against the repo on 2026-07-17. Volatile ones re-verify with:

| Claim | Re-verify |
|---|---|
| Leak still owner-accepted, ledger current | `grep -i accepted /Users/schnapp/code/schnapp-vault/memory/credential-leak-2026-06-17.md` |
| Newest ADR / any new reversals | `ls /Users/schnapp/code/schnapp-os/decisions/ | tail -3` |
| Newest handoff vs PROGRESS (resume-point gap) | `ls /Users/schnapp/code/schnapp-os/handoffs/ | tail -2; tail -3 /Users/schnapp/code/schnapp-os/PROGRESS.md` |
| Orphan worktrees still present | `git -C /Users/schnapp/code/schnapp-os worktree list` |
| Freshness gate still tracked-files-only | `grep -n "ls-files" /Users/schnapp/code/schnapp-os/scripts/check-freshness.sh` |
| memory-mcp write fix still deployed | `git -C /Users/schnapp/code/schnapp-os log --oneline -5 -- connectors/memory-mcp` |
| Portal misdelivery recurrence evidence | Mac: `tail -50 ~/mcp.err.log` (call_id ledger per ADR 0034) |
| Substrate P2/P3 fate | `grep -rn "P2\|P3" /Users/schnapp/code/schnapp-os/handoffs/ | tail -5` and `ls decisions/ | tail` |
| Stale-note scan clean | `bash /Users/schnapp/code/schnapp-os/scripts/scan-stale-notes.sh` |
