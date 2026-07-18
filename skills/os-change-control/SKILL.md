---
name: os-change-control
description: Use when landing ANY change to schnapp-os and you need to know how changes are classified and gated - "should I branch or PR", "do I need an ADR", "what must land in the same commit", "why did the hook/CI gate block my push", "how do I add a skill / edit a rule / change a hook / touch a connector", "can I git revert", "the Stop hook won't let me stop", "the learning loop held my edit", or onboarding a fresh session that must not violate main-only, the same-commit tracker rule, or the enforcement ladder.
---

# os-change-control

How changes are classified, gated, and landed in schnapp-os. Read this before your first commit.
Repo: `/Users/schnapp/code/schnapp-os` (path = this machine's clone; other machines clone under
`~/code`). Every non-negotiable below carries its rationale and the incident that created it,
because the gates only make sense with the history attached.

Definitions used once here:
- **ADR**: Architecture Decision Record, one file per choice in `decisions/NNNN-slug.md`.
- **Tracker**: the pair of `PROGRESS.md` (append-only execution log) and the live plan doc
  (newest dated file with unflipped boxes under `docs/superpowers/plans/`).
- **Gate**: a deterministic check that blocks (hook exit 2 or red CI), as opposed to an advisory
  rule that merely loads into context.

## Doctrine 1: main only, no branches, no PRs, push immediately

Canonical: [decisions/0016-no-branches-precommit-gate.md](../../decisions/0016-no-branches-precommit-gate.md)
and [decisions/0017-web-sessions-target-main.md](../../decisions/0017-web-sessions-target-main.md).

- All work, directed and agent, commits straight to `main`. No feature branches, no PRs. Run the
  local gates (below), then push. CI runs on the push.
- Never ask "should I commit/push/merge". Committing and pushing directed work without asking is
  the rule (rules/global/working-style.md "Single operator").
- Cloud sessions that ARRIVE pinned to a `claude/*` branch (the entry point's config forces it)
  merge to main the moment checks are green and never end unmerged. Arriving on a branch means the
  launching config still carries a "Develop on branch" directive: flag it for the owner (the ADR
  0017 owner action).
- Incident behind it: the pre-0016 era used feature branches plus a `self-edit/*` branch+PR lane;
  by 2026-06-29 fourteen stray branches had accumulated from web sessions alone (all already merged
  or superseded, zero lost work, pure litter obscuring real state). ADR 0016 removed branches; ADR
  0017 closed the web-session loophole and added the `sync/unmerged` routine as the report-only
  backstop.
- Safety substitute for PR review: the owner reviews in real time, CI reviews on the push, and the
  autonomous learning loop has its own pre-commit gate (Doctrine 5).

## Doctrine 2: same-commit tracker rule

Canonical: [rules/global/anti-stale.md](../../rules/global/anti-stale.md) "Tracker currency".

Every commit that changes system state must, in the SAME commit:
1. Flip the matching box in the live plan doc under `docs/superpowers/plans/`.
2. Append one line to `PROGRESS.md` (date, what changed, why, pointer to commit/ADR/handoff).
3. Then push immediately so GitHub always mirrors local.

Rules inside the rule:
- Partial work is `[~]`, never `[x]`. Nothing is marked done before its verify command has run.
- `PROGRESS.md` rotates at ~600 lines per
  [decisions/0022-progress-md-rotation-policy.md](../../decisions/0022-progress-md-rotation-policy.md)
  (full verbatim snapshot to `docs/archive/`, open items carried forward explicitly).
- Incident behind it: PROGRESS.md drifted to 1281 lines of paragraph entries and two "still open"
  items were silently buried (ADR 0022 context); separately, 24 commits across ~8 sessions
  (2026-07-04..12) landed with no handoff, the top recurring process failure in the 057 audit. The
  session-start gate now warns on tracker drift.
- Enforcement: the Stop hook (Doctrine 4) blocks ending a session with unpushed commits; the
  same-commit box+line part is advisory (judgment, deliberately not gated per ADR 0026).

## Doctrine 3: ADR discipline

Canonical: [decisions/README.md](../../decisions/README.md).

- `decisions/` is append-only. Never edit a past ADR to reflect new reality; a changed choice gets
  a NEW ADR naming what it supersedes.
- **Zero `git revert` in history** (verified: no `Revert` commit subjects as of 2026-07-17). A
  reversal is a forward refactor plus a superseding ADR, never a revert commit. Example: the whole
  plugin/marketplace era (ADRs 0003-0007) was reversed by ADR 0011's ten re-decisions and later by
  ADR 0024's flatten, all forward changes.
- Reference ADRs from live docs by number and link; never paraphrase their content elsewhere.
- Load-bearing locked set (do not re-litigate without a superseding ADR): 0011 (subtract, one home
  per fact), 0016/0017 (main-only), 0023 (memory lane in the vault repo), 0024 (no plugin
  packaging), 0026 (enforcement ladder).

### ADR vs plain commit

| Needs an ADR (new `decisions/NNNN-*.md`) | Plain commit |
|---|---|
| A choice with alternatives that future sessions must not re-open (architecture, policy, a locked default) | Executing an already-decided plan step |
| Reversing or refining any prior ADR | Bug fix, typo, doc freshness |
| Adding/removing a gate, changing hook or CI enforcement strength | Regenerating a generated doc |
| A surface/connector topology change (new server, new delivery route) | Adding a skill/rule that follows existing patterns |
| Owner-accepted risk or an explicit won't-do | Content edits inside an existing component |

When unsure: if a future session could plausibly ask "why is it like this?", write the ADR.

## Doctrine 4: the hard gates (hooks + CI)

Full wiring map: [hooks/README.md](../../hooks/README.md) (project scope in
`.claude/settings.json`, machine-wide user scope written by `shell/install.sh`, ADR 0033).
Hookless surfaces (claude.ai web, iPhone, Cowork) get none of these: run the `session-hygiene`
skill there; CI (rung 4) is the only gate they cannot route around.

### Hooks that block (as of 2026-07-17)

| Gate | Fires | Blocks | Incident behind it |
|---|---|---|---|
| `hooks/no-force-push-guard.sh` (+ user-scope wrapper `global-force-push-guard.sh`) | PreToolUse Bash, BEFORE the permission check, so it holds even under `--dangerously-skip-permissions` | any `git push --force/-f/--force-with-lease/+refspec` | main-only history is unrecoverable if rewritten; replaces a buggy predecessor hook that false-matched read-only git |
| `hooks/secret-scan-on-write.sh` (+ wrapper `global-secret-scan.sh`) | PostToolUse Write/Edit AND PreToolUse Bash command TEXT (heredoc/echo-written secrets block before execution) | a literal secret value in the write | the 2026-06-17 full plaintext leak of the vault's secrets; patterns live only in `scripts/scan-secrets.sh` |
| `hooks/em-dash-on-write.sh` | PostToolUse Write/Edit | em dash (U+2014) in live files | class recurred (ADR 0026 stripped its own, then a ~790-dash class sweep across two 2026-07-01 commits: c08eb5e 285, f7351af 502) so it escalated per the ladder |
| `hooks/shellcheck-on-write.sh` | PostToolUse on `*.sh` writes | shellcheck findings, info and above | the op-wrap quote bug (SC2086 class) crash-looped all 6 launchd services 2026-06-22 |
| `hooks/session-stop-push-gate.sh` | Stop | ending a session with unpushed commits (anti-loop: warns and allows on the second attempt if the push itself is failing) | committed-but-unpushed state is invisible to every other surface |

Do not route around a gate. If a gate is wrong, fix the gate (that change itself needs the
checklist below plus, if it changes enforcement strength, an ADR).

### CI gates (GitHub Actions, run on every push to main)

| Workflow | What fails the push |
|---|---|
| `.github/workflows/freshness.yml` | stale generated doc or stale `last-verified:` (`scripts/check-freshness.sh`); the script self-test steps under `scripts/tests/` (inventory and CI/local split: `os-validation-and-qa`); broken internal links; invalid LaunchAgent plists; literal secret in any tracked file (`scripts/scan-secrets.sh`); stale credential-incident note outside the sanctioned homes (`scripts/scan-stale-notes.sh`); `check-op-refs.sh` (WARN-only as of 2026-07-17) |
| `.github/workflows/ci-lint.yml` | em dash in live files (`scripts/check-writing-style.sh`); frozen history (`decisions/`, `handoffs/`, `docs/archive/`, PROGRESS.md) is exempt |

Run the same gates locally before pushing anything that touches `hooks/` or `scripts/`:

```bash
cd /Users/schnapp/code/schnapp-os
bash scripts/check-freshness.sh
bash scripts/check-writing-style.sh
bash scripts/scan-secrets.sh --exclude 'scripts/tests/*'
bash scripts/scan-stale-notes.sh
bash scripts/check-links.sh
for t in scripts/tests/test-*.sh; do bash "$t" || echo "FAIL $t"; done
```

## Doctrine 5: the learning-loop gate and the enforcement ladder

Canonical: [decisions/0021-learning-loop-agent-sdk.md](../../decisions/0021-learning-loop-agent-sdk.md)
and [decisions/0026-enforcement-ladder-recurrence-escalation.md](../../decisions/0026-enforcement-ladder-recurrence-escalation.md).

The one autonomous writer to main is the nightly learning loop, and it goes through a
deterministic pre-commit gate, not a branch or PR:
- The distiller (`scripts/learning_distill.py`, Agent SDK, Read/Edit/Write/Grep/Glob only, no
  Bash, bounded turns and timeout) proposes an edit; `scripts/learning-worker.sh` does all git.
- `scripts/learning-gate.sh` APPROVES only a clearly-clean diff: in-scope `.md` only
  (`rules/*.md` here; `memory/*.md` in the worker's vault clone), no symlinks, added lines under
  a size cap (default 40), `updated:` bumped on changed facts, no duplicate lines. Anything else
  HOLDS: the working-tree change is discarded and a GitHub issue carries the proposed diff.
  Failure mode is "holds too much", never "merges junk".
- A gate proposal (new enforcement) can NEVER auto-land: the loop's auto-land scope is prose `.md`
  only, so code/CI/hook changes structurally cannot be committed by the bot. It drafts an
  owner-approval issue instead.

The enforcement ladder (ADR 0026), which also tells YOU when to build a gate:
1. Advisory rule (loads into context) -> 2. Memory fact (recall) -> 3. Deterministic Code hook
(Code surface only) -> 4. Surface-independent CI gate (all surfaces, strongest).

- Escalation trigger is RECURRENCE (>= 2 occurrences of the same class), never severity. First
  sighting stays advisory.
- Judgment rules (verify-before-asserting and kin) never get gates: a gate that cannot
  mechanically decide is theatre and trains route-arounds.
- Evidence: in this repo's own history, lessons that became a code/hook fix stopped recurring;
  prose-only lessons kept recurring (malformed-secret >= 4 sessions, stale-plugin-pin >= 3).
- Test before building any gate: would a staff engineer call it justified by THIS evidence?

## Landing checklists by change class

Every class ends the same way: same-commit tracker update (Doctrine 2), push, confirm CI green.

**Rule edit** (`rules/global/` or `rules/modules/`)
1. Edit in the repo, never in `~/.claude/CLAUDE.md` (this repo IS the global lane's source).
2. If the global rule SET changes (file added/removed), also update
   `templates/user-global-CLAUDE.md` and every machine's `~/.claude/CLAUDE.md` in the same change
   (the `@import` list is explicit, no globs).
3. If the edit touches working-style reply rules, keep `hooks/standing-rules.sh` in sync
   (hooks/README.md names this pairing).
4. No em dashes; `bash scripts/check-writing-style.sh`.

**Skill add** (this file's own class)
1. Create `skills/<name>/SKILL.md` at repo ROOT. Never `.claude/skills/` (double-loads;
   `.claude/` is wiring-only). Frontmatter: exactly `name` + trigger-rich `description`.
2. Regenerate BOTH generated projections of `skills/` in the same commit or CI fails:
   `bash scripts/gen-catalog.sh && bash scripts/gen-claude-ai-skills.sh` (commits `CATALOG.md`
   + `surfaces/claude-ai-skills.md`).
3. Re-run `bash shell/install.sh` so `~/.claude/skills/<name>` symlinks to the live clone
   (per-machine step; the repo change alone does not wire other machines).
4. Optional helpers go in `skills/<name>/scripts/`, shellcheck-clean.

**Hook change** (`hooks/` or its wiring)
1. Read the hook AND its wiring: project scope `.claude/settings.json`, user scope written by
   `shell/install.sh`. The hook file alone tells you nothing about when it fires.
2. Add or update a self-test under `scripts/tests/` and wire it into `freshness.yml` (every
   existing gate has one; a gate without a test has silently failed open before, see the
   no-force-push-guard's python3-absent history in its own header comment).
3. Changing enforcement strength (new gate, gate removed, block became warn) = ADR.
4. Hooks reload at session start: a changed hook does not fire in the current session.

**Connector change** (`connectors/`)
1. Secrets stay `op://` references; new env vars go in `.env.template` as URIs and get a line in
   `credentials-map.md`.
2. Restart Mac-hosted servers with `launchctl kill TERM ...`, never `kickstart -k` (SIGKILL bind
   race, ADR 0010). Render pair deploys per `connectors/*/DEPLOY.md` and `render.yaml`.
3. Topology or delivery-route change = ADR (the connector ADR trail is 0004, 0008-0010, 0020,
   0034).
4. Update the connector's README `last-verified:` if behavior changed, or freshness.yml flags it.

**Doc change**
1. Current-state only: overwrite, never strike-through or "deprecated" annotations. History goes
   to `decisions/` or a changelog. Exceptions (append-only by design): `decisions/`, `handoffs/`,
   `docs/archive/`, PROGRESS.md.
2. Never hand-edit a generated doc (`CATALOG.md`, `handoffs/README.md`,
   `surfaces/claude-ai-skills.md`): re-run its generator (`scripts/gen-catalog.sh`,
   `scripts/gen-handoff-index.sh`, `scripts/gen-claude-ai-skills.sh`).
3. Never hardcode a mutable fact the doc does not own; point at PROGRESS.md / the live plan /
   decisions/ instead.
4. `bash scripts/check-freshness.sh && bash scripts/check-links.sh` before push.

## When NOT to use this skill

- Diagnosing WHY something is broken: `os-debugging-playbook` (method) or
  `os-diagnostics-and-tooling` (probes). This skill is about landing the fix, not finding it.
- The incident history in depth: `os-failure-archaeology`. Only the incidents that justify a gate
  are summarized here.
- What the architecture IS and its invariants: `os-architecture-contract`; system overview:
  `agentic-os-reference`.
- Flags, env vars, settings values: `os-config-and-flags`. Install/bootstrap: `os-build-and-env`.
- Running services and routines: `os-run-and-operate`. Test strategy: `os-validation-and-qa`.
- Writing the docs themselves (style, structure): `os-docs-and-writing`.
- Rolling one change across all surfaces: `os-cross-surface-campaign`.
- Existing repo skills this one leans on instead of restating: `status` (whole-system state before
  a change), `session-hygiene` (hookless-surface must-happen steps), `learn-route` (where a
  correction lands), `rotate-secret` / `cleanse-secrets` (secret incidents), `pr-sweep` (clearing
  stray PRs a cloud session left).

## Provenance and maintenance

All claims verified against the working tree on 2026-07-17. Re-verify the drift-prone ones:

| Claim | Re-verify |
|---|---|
| Zero `Revert` commits in history | `git -C /Users/schnapp/code/schnapp-os log --pretty=%s \| grep -c '^Revert'` (expect 0) |
| Hook set + wiring split | `ls /Users/schnapp/code/schnapp-os/hooks/` and read `hooks/README.md` |
| Blocking hooks wired in project scope | `grep -o '"[a-z-]*\.sh' /Users/schnapp/code/schnapp-os/.claude/settings.json` |
| freshness.yml step list (self-test count grows) | `grep -c 'run: bash scripts/tests/' /Users/schnapp/code/schnapp-os/.github/workflows/freshness.yml` |
| ci-lint.yml = writing-style only | `cat /Users/schnapp/code/schnapp-os/.github/workflows/ci-lint.yml` |
| learning-gate scope + size cap | header of `/Users/schnapp/code/schnapp-os/scripts/learning-gate.sh` |
| `check-op-refs.sh` still WARN-only | header comment in `.github/workflows/freshness.yml` |
| PROGRESS rotation threshold (~600 lines) | `decisions/0022-progress-md-rotation-policy.md` |
| Live plan location | `ls -t /Users/schnapp/code/schnapp-os/docs/superpowers/plans/ \| head -3` |
| Locked ADR set | `decisions/README.md` "Load-bearing locked choices" |
