---
name: os-diagnostics-and-tooling
description: Use when you need to MEASURE the state of schnapp-os instead of eyeballing it - "run all the checks", "is the repo clean enough to push", "which gate will CI fail", "is this doc stale", "did a secret leak into a file", "is this stored token malformed", "are the connectors/LaunchAgents actually up", "how do I test the alert path", "what does this check's FAIL output mean", "why is scan-secrets failing locally but CI is green", or before committing anything to schnapp-os. The inventory of every diagnostic script, its exact invocation, PASS/FAIL signatures, and known false positives.
---

# os-diagnostics-and-tooling

Every claim about system state has a command that proves it. Run the command; never assert
from memory (rules/global/verify-before-asserting.md). This skill inventories every diagnostic
in `scripts/` and `hooks/`, how CI invokes each one, what its output means, and where each has
false-positived before.

Paths below use this machine's clones: `/Users/schnapp/code/schnapp-os` (repo root, all
commands run from here) and `/Users/schnapp/code/schnapp-vault` (memory lane). Path = this
machine's clone; substitute on another machine. Every script states its own contract in a
header comment: when in doubt, `sed -n '1,25p' scripts/<name>.sh` beats this table.

## Fast path: one-shot scoreboard

```bash
cd /Users/schnapp/code/schnapp-os
bash skills/os-diagnostics-and-tooling/scripts/diagnose-all.sh
```

Runs every hard gate exactly as CI does, plus the informational sweeps, and prints a
PASS/FAIL/INFO scoreboard. Exit 1 = a push would fail CI. Flags: `--with-tests` adds the
28-script self-test suite (as of 2026-07-17); `-v` prints full per-check output. Read-only:
it never regenerates, edits, or restarts anything.

## Hard gates (exit nonzero = CI fails the push)

CI wiring: `.github/workflows/freshness.yml` (all below except style) and
`.github/workflows/ci-lint.yml` (style). All are read-only and location-independent
(`CLAUDE_KIT_REPO` overrides the repo root).

| Check | Invocation (CI-exact) | Proves | PASS looks like | FAIL looks like |
|---|---|---|---|---|
| Doc freshness | `bash scripts/check-freshness.sh` | committed generated docs (CATALOG.md, handoffs/README.md, surfaces/claude-ai-skills.md) match a fresh regen; no `last-verified:` doc has a source committed after its date | `ok: ...` per doc, `== freshness: OK ==` | `STALE generated doc: <file>` + the exact fix command + a committed-vs-regenerated diff |
| Secret values | `bash scripts/scan-secrets.sh --exclude 'scripts/tests/*'` | no literal secret value in tracked files (the 2026-06-17 leak class) | `scan-secrets: 0 BLOCK, N WARN across M files`, exit 0 | one masked finding per line `file:line SEV label <prefix>…[len]`; any BLOCK = exit 1 (`--strict` fails WARN too) |
| Stale incident notes | `bash scripts/scan-stale-notes.sh` | no "exposed/needs rotation" phrasing outside the vault ledger and append-only history (anti-stale.md, credential-incident notes) | `scan-stale-notes: 0 finding(s) across N files` | `file:line STALE <phrase>`, exit 1. Fix = DELETE the line, never annotate |
| Links | `bash scripts/check-links.sh` | every relative markdown link in a live doc resolves | `check-links OK: N local links resolve across live docs` | broken links named, exit 1. History (decisions/, handoffs/, docs/archive/) exempt by design |
| Writing style | `bash scripts/check-writing-style.sh [FILE...]` | no em dash (U+2014) in live files | `writing-style OK (no em dashes in live files)` | `file:line` per hit, exit 1. Frozen history exempt; vault MEMORY.md index-line quotes exempt |
| op:// references | `bash scripts/check-op-refs.sh [--strict]` | every `op://web-variables/<ITEM>/...` in a tracked file names an item documented in credentials-map.md; offline, no vault access | `ok: every op:// item is documented in credentials-map.md` | items listed. WARN-only by default, exit 0 even on findings (as of 2026-07-17); `--strict` makes it fail. Promotion to hard gate is an open owner call |

Gotchas with history:

- **scan-secrets locally red, CI green**: CI passes `--exclude 'scripts/tests/*'`. A bare run
  hits the deliberate fixtures in `scripts/tests/secret-fixtures.txt` (12 BLOCK, verified
  2026-07-17). Always use the CI form to predict CI.
- **check-freshness false STALE (fixed)**: it once walked the filesystem and descended into
  git-excluded `.claude/worktrees/*` nested checkouts, reporting local-only STALE that trained
  everyone to ignore it (fixed 410e819: git-tracked files only). If it reports STALE now,
  believe it. Earlier breaks: mawk vs BSD awk, a gitignore-glob false positive.
- **check-freshness STALE after adding a component** is correct, not noise: regenerate with the
  named fix command and commit the regen in the same commit (see `os-change-control`).
- **check-writing-style** takes file args in hook mode; no args = every tracked live file.

## Informational sweeps (the OUTPUT is the signal)

These exit 0 by contract (exception: check-infra-health exits nonzero on RED, by design).
Never treat them as green because they exited 0. Read what they printed; each prints `SKIP`
rather than a false OK when its input is absent on this surface. `diagnose-all.sh` prints
every INFO check's output by default for this reason.

| Check | Invocation | Surfaces |
|---|---|---|
| Open owner items | `bash scripts/check-open-questions.sh handoffs` | the newest numbered handoff's `## Open ...` bullets (the resume point's unresolved questions) |
| Stale memory facts | `bash scripts/check-stale-facts.sh /Users/schnapp/code/schnapp-vault/memory` | facts whose `updated:` crossed 7/30/90-day thresholds; agent decides what to refresh (supersede, not append) |
| Supersede orphans | `bash scripts/check-supersede-orphans.sh /Users/schnapp/code/schnapp-vault/memory` | a fact whose `supersedes:` names a file that still exists (append-around violation). Frontmatter-aware: its predecessor grepped column 0 and matched zero real files for its whole life |
| Mac infra health | `bash scripts/check-infra-health.sh` | Mac-only, pure bash (deliberately no LLM/MCP so it cannot fail on what it watches): expected LaunchAgents loaded, ports 8765/8766/8767 LISTENing, backup age. RED lines name the dead component; it never remediates. Exception to the exit-0 contract: exits nonzero on any RED (by design) |

## Generators (measure by regenerating, never hand-edit output)

`bash scripts/gen-catalog.sh` writes CATALOG.md; `bash scripts/gen-handoff-index.sh` writes
handoffs/README.md; `bash scripts/gen-claude-ai-skills.sh` writes surfaces/claude-ai-skills.md.
Deterministic output (C-locale sort, no timestamps), so `git diff` after a regen IS the
staleness measurement: a nonempty diff means the committed copy was stale.

## Secret byte verification (before blaming a token)

A 401 on a stored secret is measured, not diagnosed by rotation. The tool is
`scripts/check-secret-bytes.sh` (category-only verdict, never prints the value). The command
block and byte-reading detail live in one home: `os-proof-and-analysis-toolkit` Recipe 1.
Full triage order: `os-debugging-playbook`.

## Connector and service health probes

- **On-demand, from a Mac**: `scripts/check-infra-health.sh` (above). From any surface with
  the Mac connector: `service_status`, `site_health`, `tunnel_status`, `op_health` tools.
- **Continuous, Mac-independent**: GitHub-hosted crons every 30 min:
  `.github/workflows/mac-liveness.yml` (dead-man's switch for the Mac trio) and
  `render-health.yml` (Render pair; doubles as keep-warm against free-tier sleep). Both open
  a deduped GitHub issue on DOWN and auto-close on recovery. Test the alert path without an
  outage: `gh workflow run mac-liveness.yml -f simulate=down` (same for render-health);
  output says SIMULATED.
- **Aggregated view**: the `status` skill probes all domains and reports one table; the
  nightly `.github/workflows/scheduled-routines.yml` runs the sweep set
  (`scheduled-tasks/run-ci-routines.sh`) and its Step Summary is the trusted overnight reading.
- First call to a slept Render service takes ~50s; a missing cloud-env tool usually means
  the network allowlist, not the connector (vault memory: `environment-access`).

## Session instrumentation (hooked surfaces)

- `hooks/session-start-gate.sh` (SessionStart): syncs to origin, surfaces dirty/unpushed/
  behind state, supersede-orphan scan, satellite-repo drift, credential-resolve check. Its
  stdout block at session start IS a diagnostic report; read it, do not scroll past.
- `hooks/session-digest.sh` (SessionEnd): appends one structured line per session to
  `/Users/schnapp/code/schnapp-vault/sessions/index.jsonl` (machine, project, timing, message
  count, last commit subject; never transcript text). Query it to measure what sessions
  actually did across machines: `tail -20` or `jq` over that file.
- Hookless surfaces (claude.ai, iPhone, Cowork) get none of this: run the `session-hygiene`
  skill's start/end procedures instead.

## Context cost measurement

"The session feels sluggish" is measurable: invoke the `context-budget` skill. It inventories
every loaded component (rules, skills, agents, MCP servers, CLAUDE.md) with per-file token
estimates (prose `words x 1.3`, code `chars / 4`) and recommends trims. Known biggest
always-load lever: `rules/global/working-style.md` at ~1.2k tokens (trim deferred, owner call,
as of 2026-07-17).

## The test suite

Every guard/loop script has a self-test in `scripts/tests/` (28 as of 2026-07-17), each a
separate CI step in freshness.yml. Run all locally:

```bash
cd /Users/schnapp/code/schnapp-os
for t in scripts/tests/test-*.sh; do bash "$t" >/dev/null 2>&1 || echo "FAIL $t"; done; echo done
```

A test PASS line looks like `== test-<name>: PASS ==`. Touching any script in `scripts/` or
`hooks/` without running its test is not done (`os-validation-and-qa` owns the QA discipline).

## When NOT to use this skill

- Something is broken and you need triage by symptom: `os-debugging-playbook`.
- "Was this failure seen before / is this risk accepted": `os-failure-archaeology`.
- Landing a change (gates as change control, ADRs, same-commit rules): `os-change-control`.
- "Where is X configured / which knob": `os-config-and-flags`.
- Whole-system health narrative for the owner: `status` skill. What is loaded on THIS
  surface: `surface-check`. Finding and scrubbing an actual leak: `cleanse-secrets`.
  Rotating a compromised credential: `rotate-secret`. Install/bootstrap: `os-build-and-env`. Running
  services day-to-day: `os-run-and-operate`.

## Provenance and maintenance

All claims verified live 2026-07-17 on this machine's clone. Re-verify each with:

- Script inventory: `ls scripts/ scripts/tests/ hooks/`
- Any script's contract: `sed -n '1,25p' scripts/<name>.sh` (headers are canonical)
- CI invocation forms: `grep -n 'run:' .github/workflows/freshness.yml .github/workflows/ci-lint.yml`
- scan-secrets CI exclude still `scripts/tests/*`: `grep scan-secrets .github/workflows/freshness.yml`
- check-op-refs still WARN-only: `grep -n 'strict' scripts/check-op-refs.sh` (default `strict=0`)
- Test count: `ls scripts/tests/test-*.sh | wc -l`
- Liveness simulate input exists: `grep -n simulate .github/workflows/mac-liveness.yml`
- infra-health expected-agent list: `sed -n '20,40p' scripts/check-infra-health.sh`
- diagnose-all wrapper still green on a clean tree: `bash skills/os-diagnostics-and-tooling/scripts/diagnose-all.sh`
