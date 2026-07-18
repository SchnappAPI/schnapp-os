---
name: os-research-frontier
description: Use when picking the NEXT ambitious improvement to schnapp-os itself - "what should this system do that no agentic OS does yet", "where can we beat state of the art", "is the learning loop actually working", "does the second brain actually remember", "can we prove the surfaces are consistent", "can we loosen the agent's scope safely", "how do we go from monitoring to predicting failures", "can intent-reading be measured", or when the owner asks for a research agenda, an experiment design, or a falsifiable milestone for a self-improvement idea. Open problems only: every item here is candidate/open, nothing is settled or promised.
---

# os-research-frontier

The open-problems map. Six frontiers where this repo could push past current agentic-OS practice,
each with: verified current state, why that falls short, the repo asset that makes the frontier
reachable, the first three concrete steps IN THIS REPO, and a falsifiable "you have a result when"
milestone. Everything below is **candidate/open** (as of 2026-07-17). Nothing here overrides change
control: any experiment lands via [os-change-control](../os-change-control/SKILL.md) (main-only,
same-commit tracker rule, ADR for each design choice).

Definitions used once:
- **Learning loop**: nightly worker (`scripts/learning-worker.sh`) that turns queued corrections
  into proposed rule/memory edits, auto-landing only what `scripts/learning-gate.sh` approves;
  holds become GitHub issues. Mechanics: [agentic-os-reference](../agentic-os-reference/SKILL.md).
- **Hookless surface**: claude.ai web/iPhone/Cowork, where no lifecycle hooks fire and discipline
  runs via the [session-hygiene](../session-hygiene/SKILL.md) skill.
- **Falsifiable milestone**: a check that can FAIL. If the milestone cannot come back red, it is
  not a result, it is a vibe.

## When NOT to use

| Need | Go to |
|---|---|
| Fix something broken now | [os-debugging-playbook](../os-debugging-playbook/SKILL.md) |
| Was this tried before / is it settled | [os-failure-archaeology](../os-failure-archaeology/SKILL.md) |
| How to land a change, gates, ADRs | [os-change-control](../os-change-control/SKILL.md) |
| Invariants a change must preserve | [os-architecture-contract](../os-architecture-contract/SKILL.md) |
| How components load, domain theory | [agentic-os-reference](../agentic-os-reference/SKILL.md) |
| How to RUN an experiment rigorously (method, controls) | os-research-methodology (sibling skill) |
| Measuring/proving a claim with numbers | os-proof-and-analysis-toolkit (sibling skill) |
| Rolling one change across all surfaces | os-cross-surface-campaign (sibling skill) |
| Regression/QA of existing behavior | os-validation-and-qa (sibling skill) |
| Current whole-system health | [status](../status/SKILL.md) |

This skill picks WHAT to attempt and defines the win condition. It does not run experiments.

## Ranking (candidate, by payoff)

Ranked by how much each unlocks. F1 caps every other frontier (a scope the owner cannot trust
stays narrow, so capability stays narrow), which is why it outranks flashier items.

| # | Frontier | Payoff logic |
|---|---|---|
| F1 | Graduated autonomy: evidence-gated scope widening | Unblocks everything; converts the owner's scope fear from a permanent cap into a measured dial |
| F2 | Learning-loop quality: acceptance rate + closing the loop on holds | The self-improvement engine; if it silently underperforms, the whole "second brain" premise leaks |
| F3 | Memory recall quality: prove the second brain remembers | Recall failures are invisible until they cost a session; no metric exists today |
| F4 | Cross-surface consistency as a testable guarantee | One conformance suite replaces per-surface trust; today consistency rests on one 2026-07-07 probe |
| F5 | Proactive drift: predict failures before probes catch them | Moves "silent stop" defense from 30-min detection to pre-failure warning |
| F6 | Intent-reading evaluation: score the intent-check | Hardest to measure; do last, once F2's eval muscles exist |

## F1. Graduated autonomy: widen scope on evidence, not vibes (candidate)

**The owner's stated fear**: hallucinating agents, so everything is scoped strictly. Verified
current scope (as of 2026-07-17): the learning gate auto-lands only `.md` diffs matching
`rules/*.md` here or `memory/*.md` in the worker's vault clone, max 40 added lines
(`LEARNING_GATE_MAX_ADDED`, `scripts/learning-gate.sh` header); 3 of the 4 repo agents are
read-only reviewers (performance-optimizer already carries Write/Edit/Bash, an existing scope
exception in this baseline); hard hook gates block force-push, secrets, unpushed stops. The fear is rational (see
[os-failure-archaeology](../os-failure-archaeology/SKILL.md): the 2026-06-17 leak, the misdelivery
incident). The research question: does strict scope cap capability more than it buys safety, and
can that be MEASURED instead of felt?

**Why SOTA falls short**: agent autonomy today is set by policy knobs chosen on intuition and
never revisited with data. No mainstream framework ratchets permissions on observed error rate.

**This repo's asset**: a deterministic gate with a single documented knob, an append-only ledger
of every proposal outcome (held issues + `scheduled-tasks/.learning-queue.archive.tsv` on the
Mac), and a culture of ADR-recorded reversals. That is exactly the instrumentation an autonomy
ratchet needs.

**First three steps in this repo**:
1. Write the trust-gate protocol as an ADR draft: pick ONE gate to widen (candidate: raise
   `LEARNING_GATE_MAX_ADDED` from 40 to 80, or add `docs/*.md` to the auto-land scope), define
   the error metric (a landed edit later reverted, corrected, or flagged by CI counts as one
   error), the window (N=20 auto-landed edits or 30 days, whichever first), and the revert
   trigger (error rate above the pre-widening baseline).
2. Build the baseline first: a read-only script beside `scripts/learning-eval.sh` that scans git
   history for auto-landed learning commits later amended/corrected, producing the pre-widening
   error rate. No widening until the baseline number exists.
3. Widen the one gate via env var override in the worker's LaunchAgent (owner-armed, per
   `scheduled-tasks/README.md` conventions), log every outcome, and at window end write the
   ratchet-or-revert ADR with the numbers in it.

**You have a result when**: a scope widening has been reverted OR ratcheted by a recorded error
rate comparison, not by feel. Failure mode that falsifies the approach: the error metric proves
ungameable to measure (reverts of learning edits are too rare or too ambiguous to count).

## F2. Learning-loop quality: acceptance rate and closing the loop on holds (candidate)

**Verified current state** (as of 2026-07-17): `scripts/learning-eval.sh` reports only topic
RECURRENCE from the processed-capture archive (git-ignored, exists only on the Mac; CI prints
SKIP). `scripts/learning-recurrence.sh` escalates a class recurring >= 2 times to a drafted gate
issue. Held proposals become GitHub issues and then NOTHING measures what happens to them: no
acceptance-rate metric, no held-issue aging report, no signal when a hold was wrong (a proposal
the owner later hand-applied anyway).

**Why this falls short**: a learning loop is only as good as its precision/recall, and neither is
measured. "Holds too much (safe)" is the gate's designed bias (`learning-gate.sh` header), but
unmeasured over-holding silently degrades the loop to a suggestion box.

**This repo's asset**: every outcome already leaves a machine-readable trace: auto-land commits on
main, hold issues on GitHub, the capture archive TSV. The data exists; only the join is missing.

**First three steps in this repo**:
1. Extend `learning-eval.sh` (or add a sibling read-only script) to report the funnel: captures
   -> proposals -> auto-landed vs held -> held issues closed-applied vs closed-rejected vs still
   open, with ages. Wire it into `scheduled-tasks/run-ci-routines.sh` next to the existing
   `learning-eval.sh` call (line 109 as of 2026-07-17).
2. Add a closed-hold convention: closing a hold issue requires a label (`applied`, `rejected`,
   `stale`) so the funnel script can classify without NLP. Document in the issue template the
   worker already generates.
3. Define the loop's first quality target as a number (candidate: held-issue median age under 7
   days; auto-land later-corrected rate under X%, X set by the F1 baseline script) and put it in
   the nightly Step Summary so drift is visible.

**You have a result when**: the nightly report can show a MONTH where the funnel numbers moved
(holds aging down, or a gate widened because precision was proven) and a month where they did
not, and the two are distinguishable. Falsified if capture volume is too low for any number to
mean anything (then the frontier collapses into F1's ratchet).

## F3. Memory recall quality: does the second brain actually remember (candidate)

**Verified current state** (as of 2026-07-17): freshness of memory is checked
(`scripts/check-stale-facts.sh`, 7/30/90-day `updated:` thresholds, read-only) but RECALL is not:
nothing tests whether a session, asked a question whose answer lives in the vault memory lane,
actually retrieves it. The only recall test anywhere is manual and in-session
([context-budget](../context-budget/SKILL.md) section 5, "Recall test"). The memory-mcp connector
exposes `memory_search`/`memory_read`, so recall is programmatically probeable from any surface.

**Why this falls short**: SOTA memory systems (and this one) measure storage hygiene, not
retrieval success. A fact that is fresh, deduplicated, and unfindable is still forgotten.

**This repo's asset**: a small flat corpus (~20 index entries in the vault's `MEMORY.md`) with a
strict schema, plus real historical questions with known answers (every handoff and ADR contains
facts a future session needed). Ground-truth Q/A pairs can be minted from history, not invented.

**First three steps in this repo**:
1. Build a recall fixture: 20-30 question/expected-fact pairs derived from vault memory files and
   recent handoffs (e.g. "how do you restart a Mac connector service" -> `launchctl kill TERM`,
   never `kickstart -k`). Store beside the skill in `skills/os-research-frontier/scripts/` or as
   a vault file; each pair cites its source file.
2. Write a runner that, per pair, calls memory-mcp `memory_search` with the question terms and
   scores hit/miss on whether the source file is in the top results. Deterministic, read-only,
   exit 0 always (informational, matching `check-stale-facts.sh` conventions).
3. Add the score to the nightly routine's Step Summary and set the falsification threshold before
   the first run (candidate: below 80% source-hit is a red flag; a DROP of more than 10 points
   between runs is a regression even above the floor).

**You have a result when**: the recall score has caught one real regression (a renamed or
badly-superseded memory file dropping a previously-passing question) before a session hit it.
Falsified if search-term choice dominates the score (then the fixture measures the runner's
phrasing, not the memory; redesign toward end-to-end session probes).

## F4. Cross-surface consistency as a testable guarantee (candidate)

**Verified current state** (as of 2026-07-17): hookless surfaces read `rules/global` live via the
portal connector, confirmed by ONE probe on 2026-07-07 (vault memory
`surfaces-live-read-default.md`). [surface-check](../surface-check/SKILL.md) reports what is
loaded HERE, [status](../status/SKILL.md) aggregates health, but neither asserts EQUIVALENCE: no
suite proves that surface X sees the same rule bytes, the same memory index, and the same skill
set as main's HEAD. A silent portal 403 degrades a surface to the stale pasted bootstrap floor
with no alarm (open thread: briefing item 5.6).

**Why this falls short**: "consistency" today is an architecture claim plus a point-in-time
probe. SOTA multi-surface agent setups have the same gap: config drift between surfaces is
discovered by behavior, not by test.

**This repo's asset**: everything canonical is git content with a known SHA. Consistency is
therefore checkable as "does this surface see bytes matching main HEAD", which any surface that
can read a file and echo a hash can answer.

**First three steps in this repo**:
1. Define the conformance contract as a doc: the minimal set a conforming surface must prove
   (reads current `rules/global/*.md` content, reaches the vault memory index, knows main's HEAD
   sha or the content hash of a sentinel file).
2. Write the sentinel: a tiny generated file (e.g. `surfaces/CONFORMANCE.md`) carrying a content
   hash of the always-load rule set, regenerated by an existing gen script pattern
   (`scripts/gen-catalog.sh` style) so CI keeps it current.
3. Write the per-surface probe as a session procedure in the doc (hookless surfaces run it via
   session-hygiene's start gate): fetch the sentinel live, compare its hash to a locally computed
   one, report CONFORMS / DEGRADED-TO-FLOOR / UNREACHABLE. Log results somewhere aggregatable
   (candidate: a vault memory fact per surface, superseded in place).

**You have a result when**: a deliberately induced drift (revoke the portal PAT in a test window,
or edit a rule and probe before propagation) is CAUGHT by the suite on a hookless surface, and an
unmodified system passes on all surfaces. Falsified if hookless surfaces cannot run the probe
unattended (then the guarantee is only as fresh as the owner's last manual run; downgrade the
claim accordingly).

## F5. Proactive drift: from 30-minute probes to prediction (candidate)

**Verified current state** (as of 2026-07-17): `mac-liveness.yml` and `render-health.yml` cron
every 30 minutes (`*/30 * * * *` in both workflows); `com.schnapp.infra-health` probes locally.
All are REACTIVE: they detect a service already down. The archaeology shows the cost of the gap
this replaced (a backup silently dead ~55 days), but detection latency is still up to 30 minutes,
and degradation-before-failure (cert expiry approaching, token nearing rotation date, disk
filling, a LaunchAgent exit-code streak) is not watched at all.

**Why this falls short**: the owner's goal is "proactive in fixing things before the owner finds
out". Detection after failure, however fast, is the previous paradigm.

**This repo's asset**: known future failure dates already sit in the repo as prose: the
~2027-05 learning-worker OAuth re-mint note, cert/tunnel renewals, PAT expiries. Prose deadlines
are exactly what goes stale; a machine-readable expiry ledger is a small step with outsized reach.

**First three steps in this repo**:
1. Create the expiry ledger: one file (candidate: `docs/expiries.md` with a strict table schema,
   or frontmatter per item) listing every known future deadline with date, blast radius, and the
   renewal command. Populate from `credentials-map.md` and the connector docs. Ask before adding
   a top-level doc (knowledge-capture rule); a `docs/` home needs no ask.
2. Add a read-only `check-expiries.sh` to the nightly routine: warn at 30 days out, escalate via
   the existing `ops-alert.sh` issue mechanism inside 7 days.
3. Add leading-indicator probes to infra-health where cheap and deterministic: launchd service
   exit-code streaks and disk headroom first. Anything requiring trend statistics is a later
   phase; label it open.

**You have a result when**: one real deadline is renewed BEFORE any probe or session hit the
failure, traceable to a ledger warning. Falsified if the ledger itself goes stale (an expiry
fires with no ledger entry); that outcome routes the fix to the ledger's own freshness gate, per
fix-the-class.

## F6. Intent-reading evaluation: can the intent-check be scored (open, hardest)

**Verified current state** (as of 2026-07-17): [intent-check](../intent-check/SKILL.md) is a
94-line reasoning procedure (surface vs core ask, checkpoint placement) invoked per request; a
per-message hook reminder keeps it salient. Nothing scores whether running it changes outcomes.

**Why this falls short**: intent-reading is the least measurable of the owner's goals, and every
"LLM judges LLM" eval imports the judge's own biases. This is genuinely unsolved in the field.

**This repo's asset**: real historical misreads exist as ground truth: every owner correction of
the form "that is not what I meant" in the capture archive and handoffs is a labeled
intent-failure case.

**First three steps in this repo**:
1. Mine the labeled set: sweep the capture archive and handoffs for intent-misread corrections;
   record each as (original ask, what was done, what was actually wanted). Expect a small N; if
   under ~10 cases, stop and let F2's funnel accumulate more before proceeding.
2. Define the only honest metric available at small N: RECURRENCE of intent-misreads per month
   (same detector philosophy as `learning-recurrence.sh`), not a per-invocation score.
3. Run a before/after comparison across a rule change to intent-check wording, using the
   recurrence rate as the outcome. Label the result suggestive, not proof; N will be tiny.

**You have a result when**: intent-misread recurrence is a tracked monthly number at all. A
falling number is weak evidence; a RISING number after an intent-check edit is strong evidence to
revert that edit. Falsified if misreads are too rare to trend (a fine outcome: it bounds the
problem's size, which is itself a finding).

## Provenance and maintenance

Every claim above is point-in-time (verified 2026-07-17). Re-verify before acting:

| Claim | Re-verify with |
|---|---|
| learning-eval measures only recurrence, no funnel | `sed -n '1,15p' /Users/schnapp/code/schnapp-os/scripts/learning-eval.sh` |
| gate scope rules/*.md, max 40 added lines | `grep -n "LEARNING_GATE_MAX_ADDED\|scope" /Users/schnapp/code/schnapp-os/scripts/learning-gate.sh \| head` |
| recurrence escalation at >= 2, read-only | `sed -n '1,20p' /Users/schnapp/code/schnapp-os/scripts/learning-recurrence.sh` |
| liveness probes are 30-min cron | `grep -n cron /Users/schnapp/code/schnapp-os/.github/workflows/mac-liveness.yml /Users/schnapp/code/schnapp-os/.github/workflows/render-health.yml` |
| stale-facts checks age only, not recall | `sed -n '1,10p' /Users/schnapp/code/schnapp-os/scripts/check-stale-facts.sh` |
| only recall test is manual, in context-budget | `grep -n -i recall /Users/schnapp/code/schnapp-os/skills/context-budget/SKILL.md` |
| intent-check has no scoring mechanism | `grep -in "score\|metric\|eval" /Users/schnapp/code/schnapp-os/skills/intent-check/SKILL.md` |
| learning-eval + stale-facts run nightly | `grep -n "learning-eval\|check-stale-facts" /Users/schnapp/code/schnapp-os/scheduled-tasks/run-ci-routines.sh` |
| live-read consistency rests on the 2026-07-07 probe | `grep -n "2026-07-07" /Users/schnapp/code/schnapp-vault/memory/surfaces-live-read-default.md` (path = this machine's clone) |

Frontier status changes (an experiment run, a milestone hit or falsified) belong in an ADR plus a
PROGRESS.md line, then update the affected frontier section here in the same commit. This file
must never claim a result its milestone check has not produced.
