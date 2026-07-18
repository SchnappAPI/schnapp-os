---
name: os-docs-and-writing
description: Use when writing or updating ANY schnapp-os document of record - "where does this fact/status/decision go", "how do I write an ADR / handoff / plan doc", "which docs must move with this commit", "can I edit PROGRESS.md / CATALOG.md / an old decision", "why did the writing-style or freshness gate fail my push", "is this file live or frozen history", "what's the handoff template", or when a session ends and the tracker/handoff/PROGRESS updates are owed. The doc taxonomy, house writing style, per-doc-type skeletons, the generated-doc rules, and the same-commit checklist.
---

# os-docs-and-writing

How to maintain the docs of record in schnapp-os without going stale or tripping a gate.
Core doctrine (read once, it governs everything below): one fact lives in one canonical file;
docs show current state only; history is append-only in its own artifacts; anything derivable
is generated. Canonical rules: [rules/global/anti-stale.md](../../rules/global/anti-stale.md)
(staleness), [rules/global/writing-style.md](../../rules/global/writing-style.md) (prose).

Paths below are repo-relative or use `/Users/schnapp/code/schnapp-os` (path = this machine's
clone; other machines clone under `~/code`).

## Doc taxonomy: what each file IS and whether you may edit it

| File / dir | Kind | Edit rule |
|---|---|---|
| `CLAUDE.md` (root) | Project lane: schnapp-os-only invariants | Live. Edit; never add status strings or restate global rules |
| `README.md` | Map of the repo | Live. No status strings; points at trackers |
| `CATALOG.md` | Component inventory | **Generated. Never hand-edit.** Re-run `scripts/gen-catalog.sh` |
| `PROGRESS.md` | Append-only execution log, one bullet per step, newest at bottom | Append only. Rotates at ~600 lines per [decisions/0022](../../decisions/0022-progress-md-rotation-policy.md) |
| `docs/superpowers/plans/*.md` | Per-initiative live plans with task checkboxes. The newest dated file with unflipped boxes is THE live plan | Flip boxes as work lands: `[x]` done (verify ran), `[~]` partial, never premature `[x]` |
| `decisions/NNNN-*.md` | ADRs: append-only "why" | Never edit a past ADR. A changed choice = NEW ADR naming what it supersedes. Pattern: [decisions/README.md](../../decisions/README.md) |
| `handoffs/NNN-*.md` | Append-only session history; highest number = resume point | New file per session from [handoffs/TEMPLATE.md](../../handoffs/TEMPLATE.md); never edit old ones |
| `handoffs/README.md` | Handoff index | **Generated** by `scripts/gen-handoff-index.sh` |
| `surfaces/claude-ai-skills.md` | Skill registration stubs for claude.ai | **Generated** by `scripts/gen-claude-ai-skills.sh` |
| `docs/*.md` (undated) | Live prose (framework, memory-lane, environment-and-access, ...) | Live. Keep current-state true; index: [docs/README.md](../../docs/README.md) |
| `docs/*-2026-*.md` dated files | Frozen point-in-time snapshots (repo reviews, research) | Read as history only. Never update |
| `docs/archive/` | Rotated PLAN/PROGRESS eras | Frozen. Never touch |
| `AUDIT.md`, `PLAN.md` | Frozen/retired: AUDIT is a superseded 2026-06-25 snapshot; PLAN is a pointer, not status | Do not update scores or add status. Their `[ ]` boxes are NOT open work |
| `docs/superpowers/specs/` | Dated design specs | Frozen once the initiative closes |

Routing shortcut: status goes to PROGRESS.md + the live plan doc, why goes to decisions/,
per-session resume state goes to handoffs/, durable cross-surface facts go to the vault memory
lane (route via the `learn-route` skill), everything else is live prose that must stay true.

## House writing style (enforced)

Full rule: [rules/global/writing-style.md](../../rules/global/writing-style.md). The load-bearing points:

- Terse imperative. Lead with the point, then the why. No preamble, no hedging.
- **No em dashes (U+2014).** Use a colon or split the sentence. This is a
  hard gate, not taste: `scripts/check-writing-style.sh` runs in CI (`ci-lint.yml`) and as a
  write-time hook, and fails the push naming file:line. Frozen history (decisions/, handoffs/,
  docs/archive/, PROGRESS.md, AUDIT.md, dated snapshots) is exempt; everything live is not.
- Reference, do not restate. Link the canonical source by path; paraphrase is drift.
- One screen per file. If it scrolls to grasp, split it or move detail behind a pointer.
- Concrete over abstract: a path, command, or example beats a description of one.
- Delete a line before adding one.

Current-state-only rule ([anti-stale.md](../../rules/global/anti-stale.md)): a live doc shows
what IS. When something changes, OVERWRITE the old value. Never leave strike-through,
"deprecated", "old:", or the old value beside the new. The record of the change goes to
decisions/ (an ADR) or PROGRESS.md, never inline. A rule is not a changelog: fix a mistake by
sharpening the rule to its current-state form, not by appending "remember not to X" lines.

## Skeletons

### ADR (`decisions/NNNN-slug.md`)

Next number (highest existing + 1, zero-padded to 4), short kebab slug. Body:

```markdown
# NNNN - <choice, as a noun phrase>

Date: YYYY-MM-DD. Status: DECIDED.

## Context
What forced a choice; the concrete evidence.

## Decision
What was chosen. What it supersedes or locks (name prior ADRs by number).

## Consequences
What this commits future work to; known costs.
```

When an ADR is owed: any architectural choice, any reversal (never `git revert`; reversals are
forward refactors with a new ADR), any locked convention. Reference ADRs from live docs by
number + link only.

### Handoff (`handoffs/NNN-slug.md`)

Copy [handoffs/TEMPLATE.md](../../handoffs/TEMPLATE.md), next 3-digit number, fill the six
fields (Goal, Facts established, Decisions + reasoning, Actions + outcomes, Status + next
steps, Open questions) plus the copy-paste primer, delete the template comment. Dense beats
long: a grounding primer, not a transcript. Contents standard + the handoff-vs-memory boundary:
[docs/memory-lane.md](../../docs/memory-lane.md) "Handoff contents". Then regenerate the index:

```bash
bash /Users/schnapp/code/schnapp-os/scripts/gen-handoff-index.sh
```

### Plan doc (`docs/superpowers/plans/YYYY-MM-DD-slug.md`)

```markdown
# Plan: <initiative>

Date: YYYY-MM-DD. ADR: [NNNN](../../../decisions/NNNN-slug.md).
Resume point: handoffs/NNN. Success = <one measurable sentence>.

- [ ] T1 <task> ... Verify: <exact command or observation>.
- [ ] T2 ...
```

Each box carries its own verify criterion. Live example:
[docs/superpowers/plans/2026-07-03-portable-shell.md](../../docs/superpowers/plans/2026-07-03-portable-shell.md).
No "current plan" pointer anywhere: the newest dated file with unflipped boxes IS the live plan
(hardcoded pointers rot, see PLAN.md's own rationale).

### PROGRESS.md line

One bullet, appended at the bottom: date, what changed, why, pointer to the handoff/ADR/commit
for narrative. Not a paragraph: the one-line spec drifted once to 10-15 line entries and forced
the 0022 rotation.

## Generated docs and their generators

| Doc | Generator | Regenerate when |
|---|---|---|
| `CATALOG.md` | `bash scripts/gen-catalog.sh` | Any rule/skill/command/hook/agent added, removed, or renamed |
| `handoffs/README.md` | `bash scripts/gen-handoff-index.sh` | Any handoff added |
| `surfaces/claude-ai-skills.md` | `bash scripts/gen-claude-ai-skills.sh` | Any skill added, removed, or renamed |

All three are deterministic (C-locale sort, no timestamps). CI
([.github/workflows/freshness.yml](../../.github/workflows/freshness.yml) via
`scripts/check-freshness.sh`) regenerates and fails the push if the committed copy differs.
Never hand-edit any of them: your edit is overwritten on the next regen and reds CI now.

`check-freshness.sh` also gates opt-in `last-verified:` docs: a doc with frontmatter
`last-verified: YYYY-MM-DD` + `sources:` list fails CI when any listed source has a commit
newer than the date. Adding prose that asserts facts about another file? Consider opting in.

## Naming and date conventions

Per [rules/global/naming-discipline.md](../../rules/global/naming-discipline.md): spell names
out, no abbreviations; dates in filenames are ISO 8601 `YYYY-MM-DD`. Repo-specific patterns:
ADRs `NNNN-kebab-slug.md`, handoffs `NNN-kebab-slug.md`, plans and frozen snapshots
`YYYY-MM-DD-kebab-slug.md`, archives `PROGRESS-archive-<oldest>-to-<newest>.md`.

## Checklist: you changed X, which docs move in the SAME commit

The same-commit rule is anti-stale.md "Tracker currency": box flip + PROGRESS line land WITH
the change, then push immediately. Full change-control detail: sibling skill `os-change-control`.

| You changed | Must also move (same commit) |
|---|---|
| Anything state-changing at all | Live plan-doc box (`[x]`/`[~]`) + one PROGRESS.md line, then push |
| Added/removed/renamed a skill, agent, command, rule, or hook | Regenerate `CATALOG.md` (a skill also regenerates `surfaces/claude-ai-skills.md`) |
| Added a handoff | Regenerate `handoffs/README.md` |
| An architectural choice or reversal | New ADR in `decisions/` |
| A rule's set of global files | `templates/user-global-CLAUDE.md` + every machine's `~/.claude/CLAUDE.md` (the `@import` list is explicit) |
| Behavior a live doc describes (hooks, install path, connector, procedure) | That doc, plus every sibling doc making the same claim (fix the class, not the instance) |
| A new env var | `.env.template` as an `op://` URI (never a value) |
| A fact a `last-verified:` doc cites as a source | Re-verify the doc, bump its date |

Before pushing a docs-touching commit, run the local gates:

```bash
cd /Users/schnapp/code/schnapp-os && bash scripts/check-freshness.sh && bash scripts/check-writing-style.sh && bash scripts/check-links.sh
```

## When NOT to use this skill

- Landing mechanics, gates, ADR-needed classification in depth: `os-change-control`.
- Why the architecture is shaped this way / invariants: `os-architecture-contract`.
- Regenerating another repo's derived docs: the `update-docs` command; architecture maps:
  `update-codemaps`.
- Routing a correction or new fact to memory vs rule vs doc: `learn-route` (and
  `rules-distill` for piled-up lessons).
- End-of-session procedure on hookless surfaces (which includes writing the handoff):
  `session-hygiene` runs the whole sequence; this skill covers what the handoff contains.
- Memory-lane file mechanics (supersede-in-place, frontmatter schema): the vault's `agents.md`
  + [docs/memory-lane.md](../../docs/memory-lane.md).

## Provenance and maintenance

Drift-prone claims, each with a re-verification command (all as of 2026-07-17):

- PROGRESS.md rotation threshold ~600 lines: `sed -n '1,12p' /Users/schnapp/code/schnapp-os/PROGRESS.md` and [decisions/0022](../../decisions/0022-progress-md-rotation-policy.md).
- Em-dash gate exempt paths: `sed -n '25,33p' /Users/schnapp/code/schnapp-os/scripts/check-writing-style.sh`.
- Generated-doc list (CATALOG.md, handoffs/README.md, surfaces/claude-ai-skills.md): `grep -n "gen-" /Users/schnapp/code/schnapp-os/scripts/check-freshness.sh` (read the gen-* invocations in the script body; the header comment has lagged the code before).
- Handoff template's six fields: `cat /Users/schnapp/code/schnapp-os/handoffs/TEMPLATE.md`.
- Live-vs-frozen split under docs/: `cat /Users/schnapp/code/schnapp-os/docs/README.md`.
- ADR count and numbering (0001-0034 as of 2026-07-17): `ls /Users/schnapp/code/schnapp-os/decisions | tail -3`.
- Handoff resume point (058 as of 2026-07-17): `ls /Users/schnapp/code/schnapp-os/handoffs | grep -E '^[0-9]' | tail -1`.
- `last-verified:` frontmatter mechanics: `sed -n '1,20p' /Users/schnapp/code/schnapp-os/scripts/check-freshness.sh`.
