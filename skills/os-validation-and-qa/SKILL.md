---
name: os-validation-and-qa
description: Use when deciding whether schnapp-os work is actually DONE - "can I mark this [x]", "what counts as verified", "how do I run the self-test suite", "how do I add a test", "the tests pass locally but what does CI run", "how do I validate a new skill/hook/connector before calling it done", "which docs carry last-verified stamps", or any acceptance call where the temptation is to claim success without a verify command having run. Evidence standards and acceptance discipline, not landing procedure. Adversarially verifying a subagent-audit claim is os-proof-and-analysis-toolkit; a live 401 or broken thing triages via os-debugging-playbook.
---

# os-validation-and-qa

What counts as evidence in schnapp-os, and the acceptance bar for calling anything done.
The constitution is [rules/global/verify-before-asserting.md](../../rules/global/verify-before-asserting.md):
confirm a thing exists or works before stating it; if you cannot verify, say so explicitly.
This skill turns that rule into concrete verify commands per component class.

Jargon, defined once: a "gate" is a script or hook that exits non-zero to block a push or stop.
A "probe" is a live call against the running system (not a file read) that proves behavior.
"CI" is GitHub Actions on `SchnappAPI/schnapp-os`. Paths below are this machine's clones
(`/Users/schnapp/code/schnapp-os`, `/Users/schnapp/code/schnapp-vault`); substitute your clone path
on other machines.

## The acceptance ladder (weakest to strongest evidence)

1. Recalled memory or a doc's claim: NOT evidence. Docs are point-in-time.
2. The file exists / the code reads right: evidence of intent, not behavior.
3. A self-test or gate script ran and exited 0: evidence the guarded behavior holds in isolation.
4. A live probe from the real consuming surface returned the expected result: the strongest
   evidence. Prefer this for anything cross-surface (example: the claude.ai live-read claim is
   stamped "probe-confirmed 2026-07-07" in [surfaces/always-loaded-instructions.md](../../surfaces/always-loaded-instructions.md),
   meaning a real claude.ai chat fetched the rule files, not that someone read the config).

Never claim a level you did not reach. "Should work" is level 2 wearing a costume.

## Checkbox discipline: [x] vs [~]

Home: [rules/global/anti-stale.md](../../rules/global/anti-stale.md) (tracker currency).
- `[x]` only AFTER the step's verify command ran and passed, in this session.
- `[~]` for partial work. Never round up.
- The box flip + PROGRESS.md line land in the same commit as the change. Landing mechanics:
  [os-change-control](../os-change-control/SKILL.md).

## The shell self-test suite (scripts/tests/)

28 `test-*.sh` files (as of 2026-07-17), one per guarded behavior. Each is standalone: exit 0 =
pass. Full run (28/28 passed 2026-07-17; takes about a minute):

```bash
cd /Users/schnapp/code/schnapp-os
for t in scripts/tests/test-*.sh; do bash "$t" || echo "FAIL $t"; done
```

Run the whole suite before pushing anything that touches `hooks/` or `scripts/`. A 2026-07-03 CI
red came from skipping exactly this ([scripts/tests/README.md](../../scripts/tests/README.md)).

**What CI runs** (as of 2026-07-17): [.github/workflows/freshness.yml](../../.github/workflows/freshness.yml)
runs 23 of the 28 as separate steps, plus the freshness gate, link check, plist validation, and
secret scans. Five tests are local-only (no CI step): `test-check-op-refs`, `test-global-secret-scan`,
`test-global-session-gate`, `test-global-vault-push`, `test-shell-install`. Local green on those
five is the only green they get, so run them locally when touching what they guard.

**Adding a test** (mirror [scripts/tests/test-open-questions.sh](../../scripts/tests/test-open-questions.sh)):
- Name: `scripts/tests/test-<guarded-thing>.sh`, one test per guarded behavior.
- Structure: `set -uo pipefail`; resolve the script under test relative to `$0`; a
  `check(){ got want label }` helper with pass/fail counters; `mktemp -d` workdirs with a
  `trap ... EXIT` cleanup; exit non-zero if any check failed.
- Never touch live state: inject queue/vault/state paths via env (`LEARNING_QUEUE`, temp dirs).
  Inert secret lookalikes live in `scripts/tests/secret-fixtures.txt`.
- Same commit: add a step to `freshness.yml` (the README calls this required) and regenerate
  nothing extra (tests are not in CATALOG.md).

## Subagent findings are claims, not facts

Rule, established by [handoffs/054-agentic-os-optimize-pass.md](../../handoffs/054-agentic-os-optimize-pass.md):
two of four parallel-audit findings ("3 LaunchAgents not loaded", "infra-health misses agents")
were disproved by live verification in the same session. Before acting on any subagent or audit
finding, re-run its underlying check yourself (the exact command, on the live system). An audit
finding you did not reproduce goes in your report labeled "unverified", never as a fix commit.

## Byte-level verification for secrets

A secret stored with a stray space, wrapping quotes, or truncation 401s exactly like a bad token
and once cost a multi-day misdiagnosis ([decisions/0019](../../decisions/0019-learning-worker-subscription-auth.md),
memory fact `malformed-stored-secret-401`). Before blaming a tool, CLI, or rotating anything,
verify the raw bytes with `scripts/check-secret-bytes.sh`. The command block and byte-reading
detail live in one home: `os-proof-and-analysis-toolkit` Recipe 1. Rotation procedure itself:
the `rotate-secret` skill.

## Validation checklist per component class

Landing mechanics (what commits together, which gate fires) are
[os-change-control](../os-change-control/SKILL.md); this table is the EVIDENCE each class needs
before its box flips to `[x]`.

| Class | Minimum evidence before "done" |
|---|---|
| **Skill** | `bash scripts/gen-catalog.sh` run and CATALOG.md committed; `bash scripts/check-freshness.sh` and `bash scripts/check-writing-style.sh` green; a fresh session (or explicit `/name` invoke) actually triggers on a description phrase. Trigger matching is behavioral: until observed, label it "untested triggers". |
| **Hook** | shellcheck clean (the `shellcheck-on-write` hook enforces this on write); fired once for real with the intended payload and produced the intended allow/block; a `scripts/tests/test-*.sh` mirror added with a `freshness.yml` step. |
| **Script / gate** | Its own `test-*.sh` passes; the full suite passes; the gate observed both firing (bad input blocked) and passing (good input allowed). A gate only tested on the happy path is unvalidated: the supersede-orphan check matched zero files for its entire life before anyone noticed. |
| **Connector** | Deployed target answers a health probe; then a LIVE probe from the actual consuming surface (a real claude.ai chat, a real Code session) returns the expected payload. Config-side checks alone do not count; date-stamp the probe in the doc that claims it works ("probe-confirmed YYYY-MM-DD"). |
| **Rule / memory edit** | Old fact superseded in place (no contradicting copy), `updated:` bumped; vault CI green after push. Routing choice: the `learn-route` skill. |

## Golden inventory: last-verified docs

Docs that carry a `last-verified:` frontmatter stamp plus a `sources:` list opt into enforcement:
[scripts/check-freshness.sh](../../scripts/check-freshness.sh) part (2) fails CI when any listed
source has a git commit newer than the stamp. Scans git-tracked `*.md` only. Current set
(as of 2026-07-18): `connectors/mac-mcp/README.md`,
`connectors/memory-mcp/README.md`, `connectors/obsidian-mcp/README.md`, `credentials-map.md`.
Bumping the stamp without re-verifying the doc's claims defeats the gate: re-check, then bump.
Part (1) of the same script separately regenerates and diffs the generated docs (`CATALOG.md`,
`handoffs/README.md`, `surfaces/claude-ai-skills.md`); those are never hand-edited.

## When NOT to use this skill

- Landing procedure, gates, ADR-vs-commit: [os-change-control](../os-change-control/SKILL.md).
- Something is broken and needs triage: [os-debugging-playbook](../os-debugging-playbook/SKILL.md);
  was it fought before: `os-failure-archaeology`.
- Why the architecture is shaped this way: [os-architecture-contract](../os-architecture-contract/SKILL.md);
  component-model theory: [agentic-os-reference](../agentic-os-reference/SKILL.md).
- Where a knob lives: `os-config-and-flags`; install/env: `os-build-and-env`; operating the
  running system: `os-run-and-operate`; probes and tooling detail: `os-diagnostics-and-tooling`.
- Whole-system health snapshot: [status](../status/SKILL.md); this surface's capabilities:
  [surface-check](../surface-check/SKILL.md).
- Secret scrub/rotation: `cleanse-secrets` / `rotate-secret`.

## Provenance and maintenance

Re-verify each drift-prone claim before trusting it (run all commands from
`/Users/schnapp/code/schnapp-os`):

| Claim | Re-verify with |
|---|---|
| 28 tests exist | `ls /Users/schnapp/code/schnapp-os/scripts/tests/test-*.sh \| wc -l` |
| Suite passes | the full-run loop above |
| 23 tests in CI / 5 local-only | `grep -c 'tests/test-' .github/workflows/freshness.yml` and diff against the `ls` |
| last-verified doc set | `git -C /Users/schnapp/code/schnapp-os grep -l '^last-verified:' -- '*.md'` |
| Generated-doc set | `grep -n 'gen-' /Users/schnapp/code/schnapp-os/scripts/check-freshness.sh` |
| check-secret-bytes flags | `bash /Users/schnapp/code/schnapp-os/scripts/check-secret-bytes.sh --help` |
| probe-confirmed live-read date | `grep -rn 'probe-confirmed' /Users/schnapp/code/schnapp-os/surfaces/` |
