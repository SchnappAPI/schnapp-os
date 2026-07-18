---
name: os-research-methodology
description: Use when a hunch, theory, or improvement idea for schnapp-os needs to become an accepted change or a documented rejection - "I think the root cause is X", "should we adopt/build Y", "is this hypothesis actually proven", "where do improvement ideas come from", "this lesson keeps recurring, should it become a gate", "how do I retire a rejected idea", or when a session is about to act on an unverified mechanism. The discipline layer: evidence bar, predict-before-run, the hunch-to-ADR lifecycle, idea sources, and when a lesson earns enforcement. For the measurement recipes use os-proof-and-analysis-toolkit; for what to research next use os-research-frontier.
---

# os-research-methodology

How a hunch becomes an accepted change in schnapp-os, and how a wrong idea dies on record
instead of resurfacing. The repo's history is the proof this discipline matters: its worst
multi-day loss came from acting on a mechanism that explained only some of the evidence
(decisions/0019), and its biggest architecture reversal (decisions/0011) came from a
deliberate re-decision pass, not from new features.

Jargon used once: **ADR** = architecture decision record, one append-only file per choice in
`decisions/`. **Handoff** = end-of-session state snapshot in `handoffs/`. **Learning loop** =
the capture-then-distill pipeline (hooks/capture-nudge.sh, scripts/learning-worker.sh) that
turns corrections into rule/memory edits. **Gate** = a deterministic hook or CI check that
blocks an action.

## 1. The evidence bar

A mechanism is accepted only when it explains ALL observations, including the negative ones,
and survives an adversarial attempt to refute it.

Checklist before you assert a root cause or claim a design is right:

- [ ] List every observation, including the ones that DON'T fit. A theory that explains the
      failure but not the control is not a theory yet.
- [ ] Run a discriminating experiment: one whose outcome differs depending on which mechanism
      is true. Not another experiment that both theories predict the same way.
- [ ] Attack it yourself: what result would DISPROVE this? If you cannot name one, you are
      pattern-matching, not reasoning.
- [ ] Verify claims from subagents/audits live before acting. Two audit claims were disproved
      in one session (handoffs/054-agentic-os-optimize-pass.md). A finding is a hypothesis.

**Worked case (the bar failed, then held): decisions/0019.** A stored OAuth token 401'd.
The first mechanism ("CLI v2.1.112 broke subscription auth") explained the 401 but was never
tested against a control, and drove a wrong switch to metered API billing that stood for days.
The correct mechanism (the vault value was stored with a leading space plus wrapping quotes,
111 bytes raw vs 108 clean) was proven with a three-arm experiment: a deliberately-invalid
control token gave the identical 401; the byte-cleaned token gave `ok`; the worker's exact
resolution replayed in a launchd-equivalent env gave `ok`. One mechanism, all three
observations. That is the bar. The general lesson is now memory `[[malformed-stored-secret-401]]`
and a hard gate, `scripts/check-secret-bytes.sh`.

## 2. Predict before you run

Write the expected output BEFORE running the command. Concretely: state the number, string,
or exit code you expect, then run, then compare.

```
# expected: 108 bytes, first 4 hex = 736b2d ("sk-a"...)
op read 'op://web-variables/CLAUDE_CODE_OAUTH_TOKEN/credential' | wc -c
```

Why this works: an unpredicted result forces you to notice you had no model. If you only look
at output after the fact, any result gets rationalized into the current theory. This is the
cheap form of pre-registration and it costs one comment line. Apply it to counts ("this grep
should hit exactly 3 files"), timings, exit codes, and diff sizes. The measurement recipes
themselves (baselines, timing loops, comparison harnesses) live in `skills/os-proof-and-analysis-toolkit/`
and `skills/performance/`; this rule is only the ordering: prediction first, run second.

## 3. The idea lifecycle in this repo

```
hunch -> capture -> spike/experiment -> ADR + implementation -> (or) documented retirement
```

| Stage | Mechanism (as of 2026-07-17) | Where it lands |
|---|---|---|
| Capture: owner correction | `hooks/capture-nudge.sh` (UserPromptSubmit, machine-wide) enqueues it for the nightly learning loop | capture queue -> rules/memory edits |
| Capture: tabled/deferred idea | `hooks/idea-sweep.sh` (SessionEnd) sweeps the transcript into the schnapp-console Idea inbox (port 4747) | Idea inbox, deduped |
| Capture: manual, any surface | `skills/learn-route/` classifies and routes; hookless surfaces use `skills/session-hygiene/` | rule, memory fact, or doc fix |
| Spike | Run the discriminating experiment (section 1) with predictions (section 2); stress-test the design with `skills/grill-me/` or `skills/council/` before building | evidence in the eventual ADR |
| Accept | ADR in `decisions/` + implementation, landed per `skills/os-change-control/` (main-only, same-commit tracker rule) | append-only history + working code |
| Retire | Record the rejection WITH its evidence: as the "Alternatives considered" section of the winning ADR, or its own ADR if the idea was standalone | `decisions/`, so no session re-tries it |

Rules of the lifecycle:

- A hunch never skips to implementation. The spike is where most hunches should die cheaply.
- A rejection without a recorded reason is a rejection that will be re-litigated. The worked
  example: plugin packaging was rejected in decisions/0011, then RE-tested live in
  decisions/0033 (snapshot semantics re-confirmed on CLI 2.1.112) and re-rejected with the
  evidence written down. The second test was cheap because the first rejection named its
  mechanism (snapshot pinning goes stale); the re-test checked exactly that, found it still
  true, and closed the question again. Re-testing a settled question is fine WHEN the world
  may have changed (new CLI version); re-arguing it without new evidence is not. Check
  `skills/os-failure-archaeology/` before investigating anything that smells fought-before.
- Reversals are new ADRs, never edits of old ones and never `git revert`
  (see `skills/os-change-control/`).

## 4. Where good ideas historically came from

Mine these veins; they produced nearly every accepted change to date. All verifiable by
reading `handoffs/` and `decisions/` (append-only).

| Source | Examples | How to mine it |
|---|---|---|
| Red-team / critique passes | handoffs/056-portable-shell-redteam.md; the `/critique-os` command exists for exactly this | Run `/critique-os` or `skills/grill-me/` against a live subsystem |
| Repo audits / stocktakes | handoffs/052-streamline-closeout-audit.md, 057-setup-audit-and-fix-pass.md | Periodic full-pass with `skills/status/` + fresh eyes; verify findings live before acting |
| Owner corrections | the capture archive fed by `hooks/capture-nudge.sh`; promoted rules in `rules/global/` | Every correction is one instance of a class: generalize (anti-stale.md "fix the class") |
| Incident post-mortems | decisions/0010 (bind race), 0019 (malformed secret), 0029 (harness second-writer), 0034 (portal misdelivery) | Each incident yields a mechanism + a detection or gate; write both |
| Subtraction passes | decisions/0011: ten decisions re-decided, most by deleting (plugin era, module gallery, chat-memory) | Ask "what would we NOT build today"; deletion is a first-class outcome |

Notably absent: ideas from speculative feature brainstorms rarely survived. The 11-part
maximalist plan was the thing decisions/0011 subtracted. Bias toward ideas grounded in an
observed failure or an observed cost.

## 5. When a lesson earns a hard gate

Canonical policy: decisions/0026; ladder detail and the justified-by-THIS-evidence test:
`os-change-control` Doctrine 5. The two decision questions:

- **Escalation trigger is RECURRENCE (>= 2 occurrences of the same class), never severity.**
  A new lesson starts as prose. Severity is subjective and gates rare drama while missing the
  frequent quiet classes.
- Only DETERMINISTIC lessons (a mechanical check exists) get gates. Judgment rules
  (verify-before-asserting and kin) never do: a gate that cannot mechanically decide
  right-from-wrong is theatre that trains route-arounds.
- The loop automates the detection: `scripts/learning-recurrence.sh` counts class signatures
  over the capture archive and, on a fresh recurrence, drafts a gate as a GitHub issue for
  owner approval. Gates never auto-land; the auto-land path (`scripts/learning-gate.sh`) is
  scoped to `.md` under `rules/` or `memory/` by construction.
- The evidence for the policy is the repo's own natural experiment: lessons that became
  code/hook fixes stopped recurring; lessons that stayed prose kept recurring
  (malformed-secret >= 4 sightings before its gate).

If the class has not recurred, write prose and wait.

## 6. Anti-patterns (fenced)

- **Fixing the instance, not the class.** One stale line found means one class of stale lines
  exists; sweep the repo for siblings in the same pass (rules/global/anti-stale.md).
- **Capitulating to pushback without evidence.** Change position only when a new observation
  or better argument arrives, and name what changed it (rules/global/working-style.md).
  Symmetrically: do not hold a position the evidence has left.
- **Marking done before verify.** Nothing is `[x]` until its verify command has run; partial
  is `[~]` (rules/global/anti-stale.md, same-commit tracker rule). "It should work" is a
  prediction, not a result.
- **Acting on the first mechanism that fits.** The 0019 misdiagnosis cost days and a wrong
  billing switch. Run the control.
- **Rotating/rebuilding reflexively on a mystery failure.** Check raw bytes, allowlists, and
  the known-failure catalog (`skills/os-debugging-playbook/`) before destructive remedies.
- **Re-fighting settled battles.** Owner-accepted risks and documented rejections are closed
  (`skills/os-failure-archaeology/`). Reopen only with new evidence, via a new ADR.

## When NOT to use this skill

- Need the concrete measurement/analysis recipes (timing, baselines, comparison runs):
  `skills/os-proof-and-analysis-toolkit/` (and `skills/performance/` for perf specifically).
- Deciding WHAT to research or improve next: `skills/os-research-frontier/`.
- Landing the resulting change (commits, gates, ADR mechanics): `skills/os-change-control/`.
- Triaging a live breakage: `skills/os-debugging-playbook/`.
- Checking whether the question was already fought: `skills/os-failure-archaeology/`.
- Understanding an architectural invariant before proposing a change: `skills/os-architecture-contract/`.
- Routing a single fresh correction right now: `skills/learn-route/`.

## Provenance and maintenance

Volatile claims and their re-verification commands (paths are this machine's clone;
other machines substitute their own `~/code/schnapp-os`):

| Claim | Re-verify |
|---|---|
| capture-nudge is the correction trigger | `head -20 /Users/schnapp/code/schnapp-os/hooks/capture-nudge.sh` |
| idea-sweep feeds the console Idea inbox on port 4747 | `head -15 /Users/schnapp/code/schnapp-os/hooks/idea-sweep.sh` |
| recurrence >= 2 drafts a gate; gates never auto-land | `grep -n "recurrence\|auto-land" /Users/schnapp/code/schnapp-os/decisions/0026-enforcement-ladder-recurrence-escalation.md` |
| auto-land scoped to rules/memory .md | `grep -n "rules\|memory" /Users/schnapp/code/schnapp-os/scripts/learning-gate.sh \| head` |
| 0019 three-arm evidence + byte counts | `sed -n '12,21p' /Users/schnapp/code/schnapp-os/decisions/0019-learning-worker-subscription-auth.md` |
| plugin route re-rejected on live snapshot test | `grep -n "re-tested" /Users/schnapp/code/schnapp-os/decisions/0033-portable-shell-user-scope-wiring.md` |
| sibling skills exist under skills/ | `ls /Users/schnapp/code/schnapp-os/skills/` |
| newest handoff = resume point (058 as of 2026-07-17) | `ls /Users/schnapp/code/schnapp-os/handoffs/ \| sort \| tail -3` |
