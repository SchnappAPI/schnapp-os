# 0026 - Enforcement ladder + recurrence-escalation policy

Date: 2026-07-01. Status: DECIDED (streamline Phase 3, T4). Realizes the design spec's Domain 2
([docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md](../docs/superpowers/specs/2026-06-30-schnapp-os-streamline-design.md) §4). Builds on decisions/0016 + 0021 (the learning loop) and 0019 (malformed-secret).

## Context
The pre-streamline audit found a natural experiment in schnapp-os's own history: lessons that became
a code or hook fix STOPPED recurring; lessons that became only prose KEPT recurring (malformed-secret
bytes >= 4 sessions, stale-plugin-pin >= 3). Enforcement stops recurrence; documentation does not.

But enforcement is not free. A gate costs build + maintenance, and a gate built around a JUDGMENT
rule (one with no mechanical check) ossifies into a fake gate that blocks on a heuristic and trains
the operator to route around it. So "enforce more" is wrong; "enforce the RIGHT things at the RIGHT
strength, triggered by evidence" is the policy this ADR fixes.

## Decision

### The ladder (weak -> strong)
1. **Advisory rule** (read-gated) - loads into context, relies on the agent reading it.
2. **Memory fact** (recall-gated) - surfaces when relevant via recall.
3. **Deterministic Code hook** (Code-only) - fires at the moment of action, but only on the Claude
   Code surface.
4. **Surface-independent CI gate** (ALL surfaces) - the push-gate; the only rung a hookless surface
   (claude.ai web, Cowork, iPhone) cannot route around. Strongest.

### Escalation trigger = RECURRENCE, not severity
- A new lesson starts at rung 1-2 (advisory / memory). It is NOT gated on first sighting.
- When the SAME class recurs (>= 2 occurrences) it becomes a candidate to escalate to a gate.
- Severity does not trigger escalation: severity is subjective and would gate rare high-drama noise
  while missing the frequent-but-quiet classes that actually cost time. Frequency is the signal.

### Which rung: deterministic vs judgment
- **Deterministic** (a mechanical check exists) -> build a gate. CI-first (rung 4, all surfaces);
  add a Code hook (rung 3) for point-of-action speed.
- **Judgment** (verify-before-asserting, generalize-the-fix, and their kin) -> NO fake gate. Keep it
  on the lean always-load shelf (it DOES load) + an optional Code point-of-action nudge. A gate that
  cannot mechanically decide right-from-wrong is theatre.

### Discipline
- Do NOT gate what has not recurred. Do NOT gate judgment. The test before building any gate: would a
  staff engineer call this gate justified by THIS evidence?

### The loop compounds this (a wired mechanism, not a shelf policy)
- The nightly learning worker counts error-class frequency over the local capture archive. On a
  repeat (>= 2, deterministic signature) it DRAFTS a gate - a proposal, as a GitHub issue for owner
  approval - instead of writing another prose fact. Learning compounds into ENFORCEMENT, not
  documentation.
- The draft NEVER auto-lands. Gates are code/CI/hooks; the loop's auto-land path is deliberately
  scoped to `.md` under `rules/` or `memory/` (`scripts/learning-gate.sh`), so a gate proposal
  structurally cannot be committed or pushed by the autonomous loop. A class is marked "drafted" (and
  held out of prose distillation) ONLY once its issue is actually filed; a filing failure falls back
  to prose and retries, never orphaning the lesson. Building enforcement stays an owner decision.

## Applied to the open classes (spec §4.3)
- **malformed-secret bytes** (>= 4) - deterministic -> byte-check gate `scripts/check-secret-bytes.sh`
  + `rotate-secret` verify step (Phase 3 T1, commit ec08400).
- **stale-plugin-pin** (>= 3) - caused BY the plugin packaging; the Phase 2 flatten DELETED the class
  (decisions/0024). No new gate.
- **prose-doc staleness** - keep `freshness.yml`; extend `last-verified` where a deterministic in-repo
  source exists (Phase 3 T3, commit 46b1f31: credentials-map + 3 connector READMEs). Residual is
  judgment -> advisory.
- **recurrence -> drafted gate** - the loop rewire itself (Phase 3 T2, commits a9acefc + e419fbc):
  `scripts/learning-recurrence.sh` counts the archive and drafts an owner-approval issue.
- **tracker-currency / verify-before-asserting / generalize-the-fix** - NOT recurred (or judgment) ->
  stay advisory. Not gated.

## Consequences
- Learning compounds into enforcement, but only the owner lands a gate - no autonomous gate can reach
  main.
- Judgment rules are protected from being frozen into fake gates.
- The un-recurred is never gated, so the gate set stays small + justified (no premature ossification).
- A new cost: the recurrence signature is a heuristic over free text. Both error directions are safe -
  a miss just fails to draft (nothing wrongly lands); a false-positive drafts an issue the owner
  reviews and closes.

## Alternatives considered
- **Severity-triggered gating** - rejected: severity is subjective; it gates rare noise and misses
  frequent quiet classes.
- **Auto-landing gates from the loop** - rejected: a gate is code/CI and needs human judgment; the
  auto-land path is scoped to prose `.md` on purpose (decisions/0016).
- **Gate every captured lesson** - rejected: ossifies judgment, trains route-arounds, and bloats the
  gate set. Recurrence + determinism are the filters.

## References
Spec §4; decisions/0016 (no-branch learning loop), 0019 (malformed-secret), 0021 (Agent-SDK loop),
0024 (flatten deletes stale-plugin-pin). Phase 3 handoffs [047](../handoffs/047-phase-3-t1-secret-gate-done.md) + 048. Memory: [[malformed-stored-secret-401]].
